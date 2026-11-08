/// One completed set, the only input the PR logic needs.
class PerformedSet {
  const PerformedSet(this.weightKg, this.reps);
  final double weightKg;
  final int reps;
}

class PersonalRecord {
  const PersonalRecord({required this.maxWeight, required this.best1RM, required this.maxReps});
  final double maxWeight;
  final double best1RM;
  final int maxReps;
}

/// Epley formula; a single rep is the weight itself.
double estimate1RM(double weightKg, int reps) =>
    reps <= 0 ? 0 : (reps == 1 ? weightKg : weightKg * (1 + reps / 30));

/// Best marks over [sets]; sets without reps are ignored. Null when nothing valid.
PersonalRecord? calculatePR(Iterable<PerformedSet> sets) {
  double maxW = 0, best = 0;
  var maxR = 0;
  var any = false;
  for (final s in sets) {
    if (s.reps <= 0) continue;
    any = true;
    if (s.weightKg > maxW) maxW = s.weightKg;
    final e = estimate1RM(s.weightKg, s.reps);
    if (e > best) best = e;
    if (s.reps > maxR) maxR = s.reps;
  }
  return any ? PersonalRecord(maxWeight: maxW, best1RM: best, maxReps: maxR) : null;
}

/// True when [current] improves on a previous record. First-ever performance is not a "break".
/// Bodyweight work (no load) is judged by reps.
bool beatsRecord(PersonalRecord? previous, PersonalRecord current) {
  if (previous == null) return false;
  if (current.maxWeight > previous.maxWeight || current.best1RM > previous.best1RM) return true;
  return current.maxWeight == 0 && current.maxReps > previous.maxReps;
}
