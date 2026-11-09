import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/fit_widgets.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../goals/data/goals_providers.dart';
import '../domain/workout_models.dart';

/// Celebration shown right after finishing a workout: totals, streak, week progress and new records.
class WorkoutDonePage extends ConsumerWidget {
  const WorkoutDonePage({super.key, required this.result});
  final WorkoutResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final stats = ref.watch(trainingStatsProvider).value;
    final d = result.duration;
    String two(int n) => n.toString().padLeft(2, '0');
    final duration = d.inHours > 0 ? '${d.inHours}:${two(d.inMinutes % 60)}' : '${d.inMinutes}:${two(d.inSeconds % 60)}';
    final durationUnit = d.inHours > 0 ? 'h' : 'min';

    return Scaffold(
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              children: [
                const Center(child: _Badge()),
                const SizedBox(height: 20),
                _FadeUp(
                  delay: 150,
                  child: Column(children: [
                    Semantics(
                      header: true,
                      child: Text(l10n.workoutDoneTitle.toUpperCase(),
                          textAlign: TextAlign.center, style: display(42, italic: true)),
                    ),
                    const SizedBox(height: 8),
                    Text(l10n.workoutDoneSubtitle(result.name),
                        textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, fontSize: 15)),
                  ]),
                ),
                const SizedBox(height: 24),
                _FadeUp(
                  delay: 300,
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.3,
                    children: [
                      _Stat(Icons.timer_rounded, AppColors.sky, l10n.statDuration, duration, durationUnit),
                      _Stat(Icons.fitness_center_rounded, AppColors.accent, l10n.statVolume,
                          fmtThousands(result.volumeKg), 'kg'),
                      _Stat(Icons.check_circle_rounded, AppColors.lime, l10n.statSets, '${result.sets}', null),
                      _Stat(Icons.format_list_numbered_rounded, AppColors.gold, l10n.statExercises,
                          '${result.exercises}', null),
                    ],
                  ),
                ),
                if (stats != null) ...[
                  const SizedBox(height: 12),
                  _FadeUp(
                    delay: 450,
                    child: Panel(
                      child: Row(children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3A1D10),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(Icons.local_fire_department_rounded, color: AppColors.accent, size: 32),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(l10n.streakTitle, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                            BigValue('${stats.dayStreak}', unit: l10n.daysCount(stats.dayStreak).split(' ').last, size: 34),
                            Text(l10n.streakKeepGoing(stats.dayStreak),
                                style: const TextStyle(fontSize: 12, color: AppColors.textSoft)),
                            const SizedBox(height: 12),
                            Row(children: [
                              Text(l10n.weekThisWeek, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                              const Spacer(),
                              Text('${stats.thisWeek}/${stats.goal}',
                                  style: display(18, color: AppColors.lime, weight: FontWeight.w700)),
                            ]),
                            const SizedBox(height: 6),
                            ThinBar(value: stats.thisWeek / stats.goal),
                          ]),
                        ),
                      ]),
                    ),
                  ),
                ],
                if (result.records.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _FadeUp(
                    delay: 600,
                    child: Panel(
                      color: const Color(0xFF231B0B),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Icon(Icons.emoji_events_rounded, color: AppColors.gold, size: 36),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(l10n.newRecordsTitle.toUpperCase(), style: display(24, color: AppColors.gold, italic: true)),
                            const SizedBox(height: 6),
                            for (final name in result.records)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text('• $name', style: const TextStyle(fontWeight: FontWeight.w600)),
                              ),
                          ]),
                        ),
                      ]),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.pushReplacement('/history/${result.workoutId}'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  child: Text(l10n.viewDetail),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => context.go('/'),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  child: Text(l10n.backHome),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Lime check that pops in with a soft glow.
class _Badge extends StatelessWidget {
  const _Badge();

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 700),
        curve: Curves.elasticOut,
        builder: (_, t, child) => Transform.scale(scale: t, child: child),
        child: Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.lime,
            boxShadow: [BoxShadow(color: AppColors.lime.withValues(alpha: 0.35), blurRadius: 48, spreadRadius: 6)],
          ),
          child: const Icon(Icons.check_rounded, size: 64, color: AppColors.bg),
        ),
      );
}

/// Fades and slides its child up after [delay] milliseconds.
class _FadeUp extends StatefulWidget {
  const _FadeUp({required this.child, this.delay = 0});
  final Widget child;
  final int delay;

  @override
  State<_FadeUp> createState() => _FadeUpState();
}

class _FadeUpState extends State<_FadeUp> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 450));

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: a,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.15), end: Offset.zero).animate(a),
        child: widget.child,
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.icon, this.color, this.label, this.value, this.unit);
  final IconData icon;
  final Color color;
  final String label, value;
  final String? unit;

  @override
  Widget build(BuildContext context) => Panel(
        radius: 20,
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted))),
          ]),
          const Spacer(),
          BigValue(value, unit: unit, size: 34),
        ]),
      );
}
