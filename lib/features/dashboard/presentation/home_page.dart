import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/format.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../goals/data/goals_providers.dart';
import '../../progress/data/body_repository.dart';
import '../../routines/data/routine_repository.dart';
import '../../workout/data/workout_repository.dart';
import '../domain/suggestion.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appName)),
      body: AsyncBody<TrainingStats>(
        value: ref.watch(trainingStatsProvider),
        onRetry: () => ref.invalidate(historyProvider),
        builder: (stats) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(toBeginningOfSentenceCase(DateFormat.MMMMEEEEd('es').format(DateTime.now())),
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            const _TodayWorkoutCard(),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _StatCard(Icons.local_fire_department, '${stats.dayStreak}', l10n.streakDays)),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(Icons.calendar_month, '${stats.weekStreak}', l10n.streakWeeks)),
            ]),
            const SizedBox(height: 12),
            _WeekCard(stats),
            const SizedBox(height: 12),
            const _WeightCard(),
            const _ExtraCards(),
          ],
        ),
      ),
    );
  }
}

/// Hook for sections added by later features (calories); kept separate to avoid import cycles.
class _ExtraCards extends StatelessWidget {
  const _ExtraCards();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _StatCard extends StatelessWidget {
  const _StatCard(this.icon, this.value, this.label);
  final IconData icon;
  final String value, label;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(value, style: Theme.of(context).textTheme.headlineSmall),
                Text(label, style: Theme.of(context).textTheme.bodySmall),
              ]),
            ),
          ]),
        ),
      );
}

class _WeekCard extends StatelessWidget {
  const _WeekCard(this.stats);
  final TrainingStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l10n.weekProgress, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(l10n.weekProgressCount(stats.thisWeek, stats.goal)),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (stats.thisWeek / stats.goal).clamp(0, 1).toDouble(),
            minHeight: 10,
            borderRadius: BorderRadius.circular(8),
          ),
        ]),
      ),
    );
  }
}

class _TodayWorkoutCard extends ConsumerWidget {
  const _TodayWorkoutCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final active = ref.watch(activeWorkoutProvider).value;
    final routines = ref.watch(routinesProvider).value ?? [];
    final history = ref.watch(historyProvider).value ?? [];
    final lastDone = <int, DateTime>{};
    for (final s in history) {
      final id = s.workout.routineId;
      if (id != null && (lastDone[id] == null || s.workout.startedAt.isAfter(lastDone[id]!))) {
        lastDone[id] = s.workout.startedAt;
      }
    }
    final suggested = suggestRoutine(routines, lastDone);
    final scheme = Theme.of(context).colorScheme;

    final String title, subtitle, action;
    final VoidCallback onTap;
    if (active != null) {
      title = l10n.workoutInProgress;
      subtitle = active.name;
      action = l10n.workoutContinue;
      onTap = () => context.push('/workout/${active.id}');
    } else if (suggested != null) {
      title = l10n.todaySuggested;
      subtitle = suggested.routine.name;
      action = l10n.workoutStart;
      onTap = () async {
        final id = await ref.read(workoutRepositoryProvider).startWorkout(suggested.routine.id);
        if (context.mounted) context.push('/workout/$id');
      };
    } else {
      title = l10n.todaySuggested;
      subtitle = l10n.routinesEmpty;
      action = l10n.routineNew;
      onTap = () => context.push('/routines/edit');
    }
    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: onTap, icon: const Icon(Icons.play_arrow), label: Text(action)),
        ]),
      ),
    );
  }
}

class _WeightCard extends ConsumerWidget {
  const _WeightCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final entries = ref.watch(bodyEntriesProvider).value ?? [];
    final withWeight = entries.where((e) => e.weightKg != null).toList();
    if (withWeight.isEmpty) return const SizedBox.shrink();
    final current = withWeight.last.weightKg!;
    final target = ref.watch(goalsProvider).value?.targetWeightKg;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.monitor_weight_outlined),
        title: Text('${fmtNum(current)} kg'),
        subtitle: Text(target == null
            ? l10n.currentWeight
            : l10n.weightToGoal(fmtNum((current - target).abs()), fmtNum(target))),
      ),
    );
  }
}
