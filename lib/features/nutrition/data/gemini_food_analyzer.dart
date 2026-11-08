import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../domain/food_models.dart';
import 'gemini_parser.dart';

/// Stable Flash model with image input (checked against ai.google.dev, Nov 2026).
const geminiModel = 'gemini-3.8-flash';

const _prompt = 'Analiza la foto de comida. Identifica cada alimento o bebida visible, estima su '
    'porción en gramos (o ml) y sus calorías y macronutrientes (proteína, carbohidratos, grasa) '
    'para esa porción. Nombres en español. Si la imagen no contiene comida, devuelve '
    'contains_food=false y foods vacío. Indica tu nivel de confianza global. Son estimaciones.';

class GeminiFoodAnalyzer implements FoodAnalyzer {
  GeminiFoodAnalyzer({
    required this.apiKey,
    http.Client? client,
    this.model = geminiModel,
    this.timeout = const Duration(seconds: 45),
  }) : _client = client ?? http.Client();

  final String apiKey;
  final http.Client _client;
  final String model;
  final Duration timeout;

  @override
  Future<FoodAnalysis> analyze(Uint8List jpegBytes) async {
    final uri = Uri.https('generativelanguage.googleapis.com', '/v1beta/models/$model:generateContent');
    final http.Response res;
    try {
      res = await _client
          .post(
            uri,
            // Header (not query string) keeps the key out of URLs and logs.
            headers: {'x-goog-api-key': apiKey, 'Content-Type': 'application/json'},
            body: jsonEncode(_requestBody(jpegBytes)),
          )
          .timeout(timeout);
    } on SocketException {
      throw const FoodAnalysisException(FoodAnalysisError.noInternet);
    } on http.ClientException {
      throw const FoodAnalysisException(FoodAnalysisError.noInternet);
    } on TimeoutException {
      throw const FoodAnalysisException(FoodAnalysisError.noInternet, 'timeout');
    }
    return _handle(res);
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
          'responseFormat': {
            'text': {'mimeType': 'APPLICATION_JSON', 'schema': geminiResponseSchema},
          },
        },
      };

  FoodAnalysis _handle(http.Response res) {
    final code = res.statusCode;
    if (code == 429) throw const FoodAnalysisException(FoodAnalysisError.quotaExceeded);
    if (code == 401 || code == 403) throw const FoodAnalysisException(FoodAnalysisError.invalidApiKey);
    if (code == 400) {
      // Google answers an invalid key with 400 + API_KEY_INVALID.
      if (res.body.contains('API_KEY_INVALID') || res.body.contains('API key not valid')) {
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
}
