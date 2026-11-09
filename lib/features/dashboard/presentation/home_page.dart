import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/fit_widgets.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../goals/data/goals_providers.dart';
import '../../nutrition/data/meal_repository.dart';
import '../../progress/data/body_repository.dart';
import '../../routines/data/routine_repository.dart';
import '../../workout/data/workout_repository.dart';
import '../domain/suggestion.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: AsyncBody<TrainingStats>(
          value: ref.watch(trainingStatsProvider),
          onRetry: () => ref.invalidate(historyProvider),
          builder: (stats) => ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Text(DateFormat("EEEE · d MMM", 'es').format(now).toUpperCase(),
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.4, color: AppColors.muted)),
              const SizedBox(height: 4),
              Semantics(
                header: true,
                child: Text.rich(TextSpan(children: [
                  TextSpan(text: '${l10n.homeHeadlineLead.toUpperCase()} '),
                  TextSpan(
                      text: l10n.homeHeadlineAccent.toUpperCase(),
                      style: const TextStyle(color: AppColors.accent)),
                ]), style: display(40, italic: true)),
              ),
              const SizedBox(height: 16),
              const _WeekStrip(),
              const SizedBox(height: 16),
              const _TodayWorkoutCard(),
              const SizedBox(height: 14),
              _RingsCard(stats),
              const SizedBox(height: 14),
              _TilesRow(stats),
            ],
          ),
        ),
      ),
    );
  }
}

/// Monday–Sunday of the current week; today in orange, trained days marked with a lime dot.
class _WeekStrip extends ConsumerWidget {
  const _WeekStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dates = ref.watch(workoutDatesProvider).value ?? const <DateTime>[];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final trained = {for (final d in dates) DateTime(d.year, d.month, d.day)};
    final letters = DateFormat.E('es');
    return Row(children: [
      for (var i = 0; i < 7; i++) ...[
        if (i > 0) const SizedBox(width: 6),
        Expanded(child: () {
          final day = monday.add(Duration(days: i));
          final isToday = day == today;
          final done = trained.contains(day);
          final fg = isToday ? AppColors.bg : AppColors.text;
          return Semantics(
            label: '${DateFormat.MMMMEEEEd('es').format(day)}${done ? ', entrenado' : ''}',
            excludeSemantics: true,
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: isToday ? AppColors.accent : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: isToday ? null : Border.all(color: AppColors.border),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(letters.format(day).substring(0, 1).toUpperCase(),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg.withValues(alpha: 0.75))),
                const SizedBox(height: 3),
                Text('${day.day}', style: display(20, color: fg, weight: FontWeight.w700)),
                const SizedBox(height: 4),
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done ? (isToday ? AppColors.bg : AppColors.lime) : Colors.transparent,
                  ),
                ),
              ]),
            ),
          );
        }()),
      ],
    ]);
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

    final String tag, title, action;
    String? meta;
    final IconData actionIcon;
    final VoidCallback onTap;
    if (active != null) {
      tag = l10n.workoutInProgress;
      title = active.name;
      action = l10n.workoutContinue;
      actionIcon = Icons.play_arrow_rounded;
      onTap = () => context.push('/workout/${active.id}');
    } else if (suggested != null) {
      tag = l10n.todaySuggested;
      title = suggested.routine.name;
      meta = l10n.routineExerciseCount(suggested.exerciseCount);
      action = l10n.workoutStart;
      actionIcon = Icons.play_arrow_rounded;
      onTap = () async {
        final id = await ref.read(workoutRepositoryProvider).startWorkout(suggested.routine.id);
        if (context.mounted) context.push('/workout/$id');
      };
    } else {
      tag = l10n.todaySuggested;
      title = l10n.routinesEmpty;
      action = l10n.routineNew;
      actionIcon = Icons.add_rounded;
      onTap = () => context.push('/routines/edit');
    }
    final isName = active != null || suggested != null;
    return Panel(
      padding: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(
          height: 112,
          child: StripeBackground(
            child: Stack(children: [
              const Positioned(
                right: -10,
                bottom: -18,
                child: Icon(Icons.fitness_center_rounded, size: 130, color: Color(0xFF2C303B)),
              ),
              Positioned(
                left: 14,
                bottom: 12,
                child: Tag(tag, color: active != null ? AppColors.lime : AppColors.accent),
              ),
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(isName ? title.toUpperCase() : title,
                style: isName ? display(34, italic: true) : Theme.of(context).textTheme.titleMedium),
            if (meta != null) ...[
              const SizedBox(height: 6),
              Text(meta, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
            ],
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onTap,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              icon: Icon(actionIcon),
              label: Text(action),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _RingsCard extends ConsumerWidget {
  const _RingsCard(this.stats);
  final TrainingStats stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final meals = ref.watch(todayMealsProvider).value ?? [];
    final kcalGoal = ref.watch(goalsProvider).value?.dailyCalories;
    final kcal = meals.fold(0.0, (s, m) => s + m.totals.kcal).round();
    final showKcal = kcalGoal != null || meals.isNotEmpty;
    final rings = [
      Ring(stats.thisWeek / stats.goal, AppColors.accent),
      if (showKcal) Ring(kcalGoal == null ? 0 : kcal / kcalGoal, AppColors.lime),
      Ring(stats.dayStreak / 7, AppColors.sky),
    ];
    return Panel(
      child: Row(children: [
        ActivityRings(
          rings: rings,
          semanticsLabel: l10n.ringsSemantics(stats.thisWeek, stats.goal, stats.dayStreak),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(children: [
            _RingLegend(l10n.ringWorkouts, '${stats.thisWeek}', '/${stats.goal}', AppColors.accent),
            if (showKcal) ...[
              const SizedBox(height: 10),
              InkWell(
                onTap: () => context.go('/meals'),
                child: _RingLegend(l10n.ringCalories, fmtThousands(kcal),
                    kcalGoal == null ? null : '/${fmtThousands(kcalGoal)}', AppColors.lime),
              ),
            ],
            const SizedBox(height: 10),
            _RingLegend(l10n.ringStreak, l10n.daysCount(stats.dayStreak), null, AppColors.sky),
          ]),
        ),
      ]),
    );
  }
}

class _RingLegend extends StatelessWidget {
  const _RingLegend(this.label, this.value, this.suffix, this.color);
  final String label, value;
  final String? suffix;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.muted))),
          Text.rich(TextSpan(children: [
            TextSpan(text: value, style: display(22, color: color, weight: FontWeight.w700)),
            if (suffix != null)
              TextSpan(text: suffix, style: display(16, color: AppColors.muted, weight: FontWeight.w600)),
          ])),
        ],
      );
}

class _TilesRow extends ConsumerWidget {
  const _TilesRow(this.stats);
  final TrainingStats stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final entries = ref.watch(bodyEntriesProvider).value ?? [];
    final withWeight = entries.where((e) => e.weightKg != null).toList();
    final target = ref.watch(goalsProvider).value?.targetWeightKg;

    final Widget weightTile;
    if (withWeight.isEmpty) {
      weightTile = _Tile(
        label: l10n.currentWeight,
        value: '—',
        footer: l10n.entryAdd,
        footerColor: AppColors.accent,
        onTap: () => context.go('/progress'),
      );
    } else {
      final current = withWeight.last.weightKg!;
      weightTile = _Tile(
        label: l10n.currentWeight,
        value: fmtNum(current),
        unit: 'kg',
        footer: target == null ? null : l10n.weightToGoal(fmtNum((current - target).abs()), fmtNum(target)),
        footerColor: AppColors.lime,
        onTap: () => context.go('/progress'),
      );
    }
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(child: weightTile),
        const SizedBox(width: 12),
        Expanded(
          child: _Tile(
            label: l10n.weekGoalStreak,
            value: '${stats.weekStreak}',
            icon: Icons.local_fire_department_rounded,
            iconColor: AppColors.accent,
            footer: l10n.weekProgressCount(stats.thisWeek, stats.goal),
            footerColor: AppColors.accent,
          ),
        ),
      ]),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.label,
    required this.value,
    this.unit,
    this.footer,
    this.footerColor = AppColors.muted,
    this.icon,
    this.iconColor,
    this.onTap,
  });

  final String label, value;
  final String? unit, footer;
  final Color footerColor;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Panel(
        radius: 20,
        padding: const EdgeInsets.all(14),
        onTap: onTap,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted))),
            if (icon != null) Icon(icon, size: 22, color: iconColor),
          ]),
          const SizedBox(height: 4),
          BigValue(value, unit: unit),
          if (footer != null) ...[
            const SizedBox(height: 4),
            Text(footer!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: footerColor)),
          ],
        ]),
      );
}
