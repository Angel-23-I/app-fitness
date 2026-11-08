import '../../routines/domain/routine_models.dart';

/// The routine trained longest ago (never-trained first, then by name) — a simple rotation.
RoutineSummary? suggestRoutine(List<RoutineSummary> routines, Map<int, DateTime> lastDone) {
  final usable = routines.where((r) => r.exerciseCount > 0).toList();
  if (usable.isEmpty) return null;
  usable.sort((a, b) {
    final da = lastDone[a.routine.id], db = lastDone[b.routine.id];
    if (da == null && db == null) return a.routine.name.compareTo(b.routine.name);
    if (da == null) return -1;
    if (db == null) return 1;
    final c = da.compareTo(db);
    return c != 0 ? c : a.routine.name.compareTo(b.routine.name);
  });
  return usable.first;
}
