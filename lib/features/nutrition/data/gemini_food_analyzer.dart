import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../domain/food_models.dart';
import 'gemini_parser.dart';

/// Low-latency model with image input; answers a food photo in about 2 s
/// (one of the two models Google recommends for new projects, ai.google.dev, Nov 2026).
const geminiModel = 'gemini-3.5-flash-lite';

/// Tried in order when the previous model is overloaded, stalls, drops the connection or cannot
/// serve the request. 3.8 Flash goes last: more capable, but it often stalls under high demand.
const geminiFallbackModels = ['gemini-3.1-flash-lite', 'gemini-3.8-flash'];

const _prompt = 'Analiza la foto de comida. Identifica cada alimento o bebida visible, estima su '
    'porción en gramos (o ml) y sus calorías y macronutrientes (proteína, carbohidratos, grasa) '
    'para esa porción. Nombres en español. Si la imagen no contiene comida, devuelve '
    'contains_food=false y foods vacío. Indica tu nivel de confianza global. Son estimaciones.';

class GeminiFoodAnalyzer implements FoodAnalyzer {
  GeminiFoodAnalyzer({
    required this.apiKey,
    http.Client? client,
    this.model = geminiModel,
    this.fallbackModels = geminiFallbackModels,
    this.timeout = const Duration(seconds: 20),
    this.retryDelay = const Duration(seconds: 2),
  }) : _client = client ?? http.Client();

  final String apiKey;
  final http.Client _client;
  final String model;
  final List<String> fallbackModels;

  /// Per attempt; a stalled model moves on to the next one instead of blocking the user.
  final Duration timeout;
  final Duration retryDelay;

  @override
  Future<FoodAnalysis> analyze(Uint8List jpegBytes) async {
    final body = jsonEncode(_requestBody(jpegBytes));
    final models = [model, ...fallbackModels];
    var lastError = FoodAnalysisError.server;
    for (var i = 0; i < models.length; i++) {
      if (i > 0) await Future<void>.delayed(retryDelay);
      final (res, failure) = await _post(models[i], body);
      if (res == null) {
        lastError = failure!;
        continue;
      }
      if (res.statusCode == 503 || res.statusCode == 500) {
        lastError = res.statusCode == 503 ? FoodAnalysisError.busy : FoodAnalysisError.server;
        continue;
      }
      if (_modelCannotServe(res)) {
        lastError = FoodAnalysisError.server;
        continue;
      }
      return _handle(res);
    }
    throw FoodAnalysisException(lastError);
  }

  /// The response, or why there is none: [FoodAnalysisError.timeout] when the model stalled,
  /// [FoodAnalysisError.noInternet] when the connection dropped (worth trying the next model).
  /// Throws right away when the device is offline, since no other model can be reached either.
  Future<(http.Response?, FoodAnalysisError?)> _post(String model, String body) async {
    final uri = Uri.https('generativelanguage.googleapis.com', '/v1beta/models/$model:generateContent');
    final http.Response res;
    final started = DateTime.now();
    try {
      res = await _client
          .post(
            uri,
            // Header (not query string) keeps the key out of URLs and logs.
            headers: {'x-goog-api-key': apiKey, 'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(timeout);
    } on SocketException catch (e) {
      _log('$model socket error: ${e.message}');
      throw const FoodAnalysisException(FoodAnalysisError.noInternet);
    } on TimeoutException {
      _log('$model gave no response after ${timeout.inSeconds}s');
      return (null, FoodAnalysisError.timeout);
    } on http.ClientException catch (e) {
      _log('$model connection error: ${e.message}');
      return (null, FoodAnalysisError.noInternet);
    } on IOException catch (e) {
      // TLS handshake failures and the like are not wrapped by package:http.
      _log('$model ${e.runtimeType}: $e');
      return (null, FoodAnalysisError.noInternet);
    }
    _log('$model HTTP ${res.statusCode} in ${DateTime.now().difference(started).inMilliseconds} ms');
    if (res.statusCode >= 400) _log(_snippet(res.body));
    return (res, null);
  }

  Map<String, Object> _requestBody(Uint8List jpeg) => {
        'contents': [
          {
            'parts': [
              {
                'inline_data': {'mime_type': 'image/jpeg', 'data': base64Encode(jpeg)},
              },
              {'text': _prompt},
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.2,
          // "low" is enough to estimate portions and is the one level every model in the chain
          // accepts: 3.8 Flash rejects "minimal" (the Flash-Lite default) with an error, and its
          // own default, "medium", often took over 45 s on a photo.
          'thinkingConfig': {'thinkingLevel': 'low'},
          'responseFormat': {
            'text': {'mimeType': 'APPLICATION_JSON', 'schema': geminiResponseSchema},
          },
        },
      };

  bool _isInvalidKey(http.Response res) =>
      res.body.contains('API_KEY_INVALID') || res.body.contains('API key not valid');

  /// 404 (model retired or renamed) or a 400 that is not about the key (the model rejected a
  /// parameter): another model may still answer, while a bad key or quota would fail everywhere.
  bool _modelCannotServe(http.Response res) =>
      res.statusCode == 404 || (res.statusCode == 400 && !_isInvalidKey(res));

  FoodAnalysis _handle(http.Response res) {
    final code = res.statusCode;
    if (code == 429) throw const FoodAnalysisException(FoodAnalysisError.quotaExceeded);
    if (code == 503) throw const FoodAnalysisException(FoodAnalysisError.busy);
    if (code == 401 || code == 403) throw const FoodAnalysisException(FoodAnalysisError.invalidApiKey);
    if (code == 400) {
      // Google answers an invalid key with 400 + API_KEY_INVALID.
      if (_isInvalidKey(res)) {
        throw const FoodAnalysisException(FoodAnalysisError.invalidApiKey);
      }
      throw FoodAnalysisException(FoodAnalysisError.server, 'HTTP 400: ${_snippet(res.body)}');
    }
    if (code < 200 || code >= 300) {
      throw FoodAnalysisException(FoodAnalysisError.server, 'HTTP $code');
    }

    final Object? body;
    try {
      body = jsonDecode(utf8.decode(res.bodyBytes));
    } on FormatException {
      throw const FoodAnalysisException(FoodAnalysisError.unparseable, 'response is not JSON');
    }
    final candidates = body is Map ? body['candidates'] : null;
    if (candidates is! List || candidates.isEmpty) {
      // No candidate usually means the prompt/image was blocked.
      throw const FoodAnalysisException(FoodAnalysisError.noFood, 'no candidates');
    }
    final parts = (candidates.first as Map?)?['content']?['parts'];
    final text = parts is List ? parts.map((p) => (p as Map)['text'] ?? '').join() : '';
    if (text.trim().isEmpty) {
      throw const FoodAnalysisException(FoodAnalysisError.unparseable, 'empty text');
    }
    return parseFoodAnalysis(text);
  }

  String _snippet(String s) => s.length > 200 ? s.substring(0, 200) : s;

  /// Debug-only diagnostics; never includes the API key (it travels only in a header).
  void _log(String message) {
    if (kDebugMode) debugPrint('Gemini: $message');
  }
}
