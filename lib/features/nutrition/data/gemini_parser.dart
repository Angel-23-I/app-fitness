import 'dart:convert';

import '../domain/food_models.dart';

/// Parses the JSON the model returns (our own contract, see [geminiResponseSchema]).
/// Tolerates markdown fences and numbers sent as strings; throws [FoodAnalysisException].
FoodAnalysis parseFoodAnalysis(String raw) {
  final Object? json;
  try {
    json = jsonDecode(_stripFences(raw));
  } on FormatException catch (e) {
    throw FoodAnalysisException(FoodAnalysisError.unparseable, e.message);
  }
  if (json is! Map<String, dynamic>) {
    throw const FoodAnalysisException(FoodAnalysisError.unparseable, 'root is not an object');
  }
  if (json['contains_food'] == false) {
    throw const FoodAnalysisException(FoodAnalysisError.noFood);
  }
  final list = json['foods'];
  if (list is! List) {
    throw const FoodAnalysisException(FoodAnalysisError.unparseable, 'missing foods');
  }
  final foods = <FoodItemDraft>[];
  for (final f in list) {
    if (f is! Map<String, dynamic>) continue;
    final name = (f['name'] as Object?)?.toString().trim() ?? '';
    final kcal = _num(f['calories']);
    if (name.isEmpty || kcal == null) continue;
    foods.add(FoodItemDraft(
      name: name,
      grams: _num(f['grams']) ?? 0,
      kcal: kcal,
      proteinG: _num(f['protein_g']) ?? 0,
      carbsG: _num(f['carbs_g']) ?? 0,
      fatG: _num(f['fat_g']) ?? 0,
    ));
  }
  if (foods.isEmpty) {
    throw FoodAnalysisException(
        list.isEmpty ? FoodAnalysisError.noFood : FoodAnalysisError.unparseable, 'no valid foods');
  }
  return FoodAnalysis(foods, _confidence(json['confidence']));
}

String _stripFences(String s) {
  final t = s.trim();
  final m = RegExp(r'^```(?:json)?\s*([\s\S]*?)\s*```$').firstMatch(t);
  return m != null ? m.group(1)! : t;
}

/// Non-negative finite number from a JSON number or numeric string.
double? _num(Object? v) {
  final d = v is num ? v.toDouble() : (v is String ? double.tryParse(v.replaceAll(',', '.')) : null);
  return d != null && d.isFinite && d >= 0 ? d : null;
}

Confidence _confidence(Object? v) => switch (v?.toString().toLowerCase()) {
      'high' => Confidence.high,
      'low' => Confidence.low,
      _ => Confidence.medium,
    };

/// JSON schema sent to the model; keep in sync with [parseFoodAnalysis].
const geminiResponseSchema = <String, Object>{
  'type': 'object',
  'properties': {
    'contains_food': {
      'type': 'boolean',
      'description': 'False when the image does not show food or a drink.',
    },
    'foods': {
      'type': 'array',
      'description': 'Each distinct food or drink visible in the image.',
      'items': {
        'type': 'object',
        'properties': {
          'name': {'type': 'string', 'description': 'Food name in Spanish.'},
          'grams': {'type': 'number', 'description': 'Estimated portion in grams (or ml for drinks).'},
          'calories': {'type': 'number', 'description': 'Estimated kilocalories for that portion.'},
          'protein_g': {'type': 'number'},
          'carbs_g': {'type': 'number'},
          'fat_g': {'type': 'number'},
        },
        'required': ['name', 'grams', 'calories', 'protein_g', 'carbs_g', 'fat_g'],
      },
    },
    'confidence': {
      'type': 'string',
      'enum': ['low', 'medium', 'high'],
      'description': 'Overall confidence of the estimate.',
    },
  },
  'required': ['contains_food', 'foods', 'confidence'],
};
