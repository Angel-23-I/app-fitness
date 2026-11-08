import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/format.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/workout_repository.dart';
import '../domain/workout_models.dart';

class HistoryDetailPage extends ConsumerWidget {
  const HistoryDetailPage({super.key, required this.workoutId});
  final int workoutId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(workoutSessionProvider(workoutId));
    return Scaffold(
      appBar: AppBar(title: Text(async.value?.workout.name ?? l10n.historyTitle)),
      body: AsyncBody<WorkoutSession?>(
        value: async,
        onRetry: () => ref.invalidate(workoutSessionProvider(workoutId)),
        builder: (s) => s == null
            ? EmptyState(icon: Icons.search_off, message: l10n.workoutNotFound)
            : ListView(padding: const EdgeInsets.all(16), children: [
                Text(fmtDateTime(s.workout.startedAt), style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 12),
                for (final b in s.blocks)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(b.exercise.name, style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 4),
                          for (var i = 0; i < b.sets.length; i++)
                            Text('${i + 1}.  ${fmtNum(b.sets[i].weightKg)} kg × ${b.sets[i].reps}'),
                        ]),
                      ),
                    ),
                  ),
              ]),
      ),
    );
  }
}
