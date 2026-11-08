import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/features/workout/domain/pr_calculator.dart';

void main() {
  test('Epley 1RM', () {
    expect(estimate1RM(100, 1), 100);
    expect(estimate1RM(100, 10), closeTo(133.33, 0.01));
    expect(estimate1RM(100, 0), 0);
  });

  test('calculatePR picks best weight, 1RM and reps; ignores empty sets', () {
    final pr = calculatePR(const [
      PerformedSet(100, 5),
      PerformedSet(80, 12),
      PerformedSet(120, 0),
    ])!;
    expect(pr.maxWeight, 100);
    expect(pr.best1RM, closeTo(116.67, 0.01)); // 100 x 5; 80 x 12 gives 112
    expect(pr.maxReps, 12);
    expect(calculatePR(const []), isNull);
    expect(calculatePR(const [PerformedSet(50, 0)]), isNull);
  });

  group('beatsRecord', () {
    final base = calculatePR(const [PerformedSet(100, 5)]);
    test('first performance is not a break', () {
      expect(beatsRecord(null, base!), isFalse);
    });
    test('heavier or higher 1RM wins, equal does not', () {
      expect(beatsRecord(base, calculatePR(const [PerformedSet(105, 3)])!), isTrue);
      expect(beatsRecord(base, calculatePR(const [PerformedSet(90, 10)])!), isTrue); // 1RM 120
      expect(beatsRecord(base, calculatePR(const [PerformedSet(100, 5)])!), isFalse);
      expect(beatsRecord(base, calculatePR(const [PerformedSet(80, 5)])!), isFalse);
    });
    test('bodyweight is judged by reps', () {
      final bw = calculatePR(const [PerformedSet(0, 10)]);
      expect(beatsRecord(bw, calculatePR(const [PerformedSet(0, 12)])!), isTrue);
      expect(beatsRecord(bw, calculatePR(const [PerformedSet(0, 8)])!), isFalse);
    });
  });
}
