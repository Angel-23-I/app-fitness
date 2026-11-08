import 'dart:typed_data';

enum Confidence { low, medium, high }

/// One food (or meal component) with its estimated portion and nutrition.
class FoodItemDraft {
  const FoodItemDraft({
    required this.name,
    required this.grams,
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  final String name;
  final double grams, kcal, proteinG, carbsG, fatG;

  /// Same food with another portion: calories and macros scale proportionally.
  FoodItemDraft withGrams(double newGrams) {
    if (grams <= 0) return copyWith(grams: newGrams);
    final f = newGrams / grams;
    return FoodItemDraft(
        name: name, grams: newGrams, kcal: kcal * f, proteinG: proteinG * f, carbsG: carbsG * f, fatG: fatG * f);
  }

  FoodItemDraft copyWith(
          {String? name, double? grams, double? kcal, double? proteinG, double? carbsG, double? fatG}) =>
      FoodItemDraft(
        name: name ?? this.name,
        grams: grams ?? this.grams,
        kcal: kcal ?? this.kcal,
        proteinG: proteinG ?? this.proteinG,
        carbsG: carbsG ?? this.carbsG,
        fatG: fatG ?? this.fatG,
      );
}

class FoodAnalysis {
  const FoodAnalysis(this.foods, this.confidence);
  final List<FoodItemDraft> foods;
  final Confidence confidence;
}

class Totals {
  const Totals({this.kcal = 0, this.proteinG = 0, this.carbsG = 0, this.fatG = 0});
  final double kcal, proteinG, carbsG, fatG;

  factory Totals.of(Iterable<FoodItemDraft> items) => Totals(
        kcal: items.fold(0, (s, e) => s + e.kcal),
        proteinG: items.fold(0, (s, e) => s + e.proteinG),
        carbsG: items.fold(0, (s, e) => s + e.carbsG),
        fatG: items.fold(0, (s, e) => s + e.fatG),
      );
}

enum FoodAnalysisError { noApiKey, noInternet, invalidApiKey, quotaExceeded, unparseable, noFood, server }

class FoodAnalysisException implements Exception {
  const FoodAnalysisException(this.error, [this.detail]);
  final FoodAnalysisError error;
  final String? detail;

  @override
  String toString() => 'FoodAnalysisException($error${detail == null ? '' : ': $detail'})';
}

/// Provider-agnostic food recognition. Implementations must throw [FoodAnalysisException].
abstract class FoodAnalyzer {
  /// [jpegBytes] is an already reduced JPEG.
  Future<FoodAnalysis> analyze(Uint8List jpegBytes);
}
