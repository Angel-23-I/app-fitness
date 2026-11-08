import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as img;
import 'package:fittrack/features/nutrition/data/food_image.dart';
import 'package:fittrack/features/nutrition/data/gemini_food_analyzer.dart';
import 'package:fittrack/features/nutrition/data/gemini_parser.dart';
import 'package:fittrack/features/nutrition/domain/food_models.dart';

const _ok = '''
{"contains_food": true, "confidence": "high", "foods": [
  {"name": "Arroz blanco", "grams": 150, "calories": 195, "protein_g": 4, "carbs_g": 42, "fat_g": 0.4},
  {"name": "Pollo a la plancha", "grams": "120", "calories": 198, "protein_g": 37, "carbs_g": 0, "fat_g": 4.3}
]}''';

FoodAnalysisError? _errorOf(void Function() f) {
  try {
    f();
  } on FoodAnalysisException catch (e) {
    return e.error;
  }
  return null;
}

void main() {
  group('parseFoodAnalysis', () {
    test('parses foods, coerces numeric strings and reads confidence', () {
      final a = parseFoodAnalysis(_ok);
      expect(a.confidence, Confidence.high);
      expect(a.foods.length, 2);
      expect(a.foods[0].name, 'Arroz blanco');
      expect(a.foods[0].fatG, 0.4);
      expect(a.foods[1].grams, 120);
      expect(Totals.of(a.foods).kcal, 393);
    });

    test('accepts markdown fences', () {
      expect(parseFoodAnalysis('```json\n$_ok\n```').foods.length, 2);
    });

    test('skips invalid entries but keeps valid ones; missing confidence is medium', () {
      final a = parseFoodAnalysis(
          '{"foods": [{"name": "", "calories": 5}, {"name": "Pan", "calories": -3}, {"name": "Manzana", "calories": 52}]}');
      expect(a.foods.single.name, 'Manzana');
      expect(a.confidence, Confidence.medium);
    });

    test('reports no food, garbage and unusable content with distinct errors', () {
      expect(_errorOf(() => parseFoodAnalysis('{"contains_food": false, "foods": []}')),
          FoodAnalysisError.noFood);
      expect(_errorOf(() => parseFoodAnalysis('{"foods": []}')), FoodAnalysisError.noFood);
      expect(_errorOf(() => parseFoodAnalysis('lo siento, no puedo')), FoodAnalysisError.unparseable);
      expect(_errorOf(() => parseFoodAnalysis('[1,2]')), FoodAnalysisError.unparseable);
      expect(_errorOf(() => parseFoodAnalysis('{"foods": [{"name": "x"}]}')), FoodAnalysisError.unparseable);
      expect(_errorOf(() => parseFoodAnalysis('{"nope": 1}')), FoodAnalysisError.unparseable);
    });
  });

  group('FoodItemDraft.withGrams', () {
    test('scales calories and macros proportionally', () {
      const d = FoodItemDraft(name: 'Arroz', grams: 100, kcal: 130, proteinG: 2.7, carbsG: 28, fatG: 0.3);
      final h = d.withGrams(50);
      expect(h.kcal, 65);
      expect(h.carbsG, 14);
    });
    test('from zero grams keeps values', () {
      const d = FoodItemDraft(name: 'x', grams: 0, kcal: 10, proteinG: 1, carbsG: 1, fatG: 1);
      expect(d.withGrams(80).kcal, 10);
    });
  });

  group('GeminiFoodAnalyzer', () {
    final jpeg = Uint8List.fromList([1, 2, 3]);

    GeminiFoodAnalyzer analyzer(http.Client c) => GeminiFoodAnalyzer(apiKey: 'KEY', client: c);
    String wrap(String text) => jsonEncode({
          'candidates': [
            {'content': {'parts': [{'text': text}]}}
          ]
        });

    test('sends key in header, image inline and the configured model', () async {
      late http.Request seen;
      final a = analyzer(MockClient((r) async {
        seen = r;
        return http.Response(wrap(_ok), 200, headers: {'content-type': 'application/json; charset=utf-8'});
      }));
      final result = await a.analyze(jpeg);
      expect(result.foods.length, 2);
      expect(seen.url.path, contains(geminiModel));
      expect(seen.headers['x-goog-api-key'], 'KEY');
      expect(seen.url.toString(), isNot(contains('KEY')));
      final body = jsonDecode(seen.body) as Map;
      final parts = body['contents'][0]['parts'] as List;
      expect(parts.first['inline_data']['data'], base64Encode(jpeg));
      expect(parts.first['inline_data']['mime_type'], 'image/jpeg');
    });

    Future<FoodAnalysisError?> errorFor(http.Client c) async {
      try {
        await analyzer(c).analyze(jpeg);
      } on FoodAnalysisException catch (e) {
        return e.error;
      }
      return null;
    }

    test('maps HTTP and network failures to specific errors', () async {
      expect(await errorFor(MockClient((_) async => http.Response('{}', 429))), FoodAnalysisError.quotaExceeded);
      expect(await errorFor(MockClient((_) async => http.Response('{}', 403))), FoodAnalysisError.invalidApiKey);
      expect(
          await errorFor(MockClient((_) async => http.Response(
              '{"error":{"status":"INVALID_ARGUMENT","message":"API key not valid.","details":[{"reason":"API_KEY_INVALID"}]}}',
              400))),
          FoodAnalysisError.invalidApiKey);
      expect(await errorFor(MockClient((_) async => http.Response('boom', 500))), FoodAnalysisError.server);
      expect(await errorFor(MockClient((_) async => throw const SocketException('offline'))),
          FoodAnalysisError.noInternet);
      expect(await errorFor(MockClient((_) async => throw http.ClientException('offline'))),
          FoodAnalysisError.noInternet);
    });

    test('maps unusable 200 responses', () async {
      expect(await errorFor(MockClient((_) async => http.Response('not json', 200))), FoodAnalysisError.unparseable);
      expect(await errorFor(MockClient((_) async => http.Response('{"candidates": []}', 200))),
          FoodAnalysisError.noFood);
      expect(await errorFor(MockClient((_) async => http.Response(wrap('hola'), 200))), FoodAnalysisError.unparseable);
      expect(await errorFor(MockClient((_) async => http.Response(wrap('{"contains_food": false, "foods": []}'), 200))),
          FoodAnalysisError.noFood);
    });
  });

  test('prepareFoodImage shrinks big images to 1024 px and rejects garbage', () async {
    final big = img.encodeJpg(img.Image(width: 3000, height: 2000), quality: 95);
    final out = img.decodeJpg(await prepareFoodImage(Uint8List.fromList(big)))!;
    expect(out.width, 1024);
    expect(out.height, closeTo(683, 1));

    final small = img.encodeJpg(img.Image(width: 400, height: 300));
    final same = img.decodeJpg(await prepareFoodImage(Uint8List.fromList(small)))!;
    expect(same.width, 400);

    await expectLater(prepareFoodImage(Uint8List.fromList([0, 1, 2])), throwsFormatException);
  });
}
