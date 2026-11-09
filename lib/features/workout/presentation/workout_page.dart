import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/fit_widgets.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../settings/data/settings_repository.dart';
import '../data/workout_repository.dart';
import '../domain/workout_models.dart';
import 'rest_timer.dart';

class WorkoutPage extends ConsumerWidget {
  const WorkoutPage({super.key, required this.workoutId});
  final int workoutId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(workoutSessionProvider(workoutId));
    final session = async.value;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        leading: Center(
          child: IconButton(
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: () => context.pop(),
            icon: const Icon(Icons.close_rounded),
            style: IconButton.styleFrom(
              fixedSize: const Size(44, 44),
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
        ),
        leadingWidth: 72,
        centerTitle: true,
        title: Column(mainAxisSize: MainAxisSize.min, children: [
          Text((session?.workout.name ?? l10n.workoutTitle).toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2, color: AppColors.muted)),
          if (session != null) _Elapsed(session.workout.startedAt),
        ]),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (v) async {
              if (v == 'discard' && await _confirm(context, l10n.workoutDiscardTitle, l10n.workoutDiscardBody)) {
                await ref.read(workoutRepositoryProvider).discard(workoutId);
                if (context.mounted) context.pop();
              } else if (v.startsWith('rest')) {
                await ref
                    .read(settingsRepositoryProvider)
                    .set(SettingKeys.restSeconds, v.substring(4));
              }
            },
            itemBuilder: (_) => [
              for (final s in const [30, 60, 90, 120, 180])
                PopupMenuItem(value: 'rest$s', child: Text(l10n.restDuration(s))),
              const PopupMenuDivider(),
              PopupMenuItem(value: 'discard', child: Text(l10n.workoutDiscard)),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: session == null ? null : () => _finish(context, ref, session),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.lime,
                foregroundColor: AppColors.bg,
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(l10n.workoutFinish),
            ),
          ),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: AsyncBody<WorkoutSession?>(
            value: async,
            onRetry: () => ref.invalidate(workoutSessionProvider(workoutId)),
            builder: (s) => s == null
                ? EmptyState(icon: Icons.search_off, message: l10n.workoutNotFound)
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    children: [
                      _Segments(s.blocks),
                      const SizedBox(height: 14),
                      for (var i = 0; i < s.blocks.length; i++)
                        _BlockCard(workoutId: workoutId, order: i, total: s.blocks.length, block: s.blocks[i]),
                    ],
                  ),
          ),
        ),
        const RestTimerBar(),
      ]),
    );
  }

  Future<void> _finish(BuildContext context, WidgetRef ref, WorkoutSession s) async {
    final l10n = AppLocalizations.of(context);
    if (!s.hasCompletedSet) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.workoutNothingDone)));
      return;
    }
    if (!await _confirm(context, l10n.workoutFinishTitle, l10n.workoutFinishBody)) return;
    final now = DateTime.now();
    final broken = await ref.read(workoutRepositoryProvider).finish(workoutId);
    ref.read(restTimerProvider.notifier).stop();
    if (!context.mounted) return;
    HapticFeedback.mediumImpact();
    context.pushReplacement('/workout-done',
        extra: WorkoutResult.fromSession(s, now, records: [for (final e in broken) e.name]));
  }
}

Future<bool> _confirm(BuildContext context, String title, String body) async {
  final l10n = AppLocalizations.of(context);
  return await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.ok)),
          ],
        ),
      ) ??
      false;
}

/// Time since the workout started, ticking every second.
class _Elapsed extends StatefulWidget {
  const _Elapsed(this.startedAt);
  final DateTime startedAt;

  @override
  State<_Elapsed> createState() => _ElapsedState();
}

class _ElapsedState extends State<_Elapsed> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = DateTime.now().difference(widget.startedAt);
    String two(int n) => n.toString().padLeft(2, '0');
    final text = d.inHours > 0
        ? '${d.inHours}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}'
        : '${two(d.inMinutes)}:${two(d.inSeconds % 60)}';
    return Text(text,
        style: display(26, weight: FontWeight.w700).copyWith(fontFeatures: const [FontFeature.tabularFigures()]));
  }
}

bool _blockDone(ExerciseBlock b) => b.sets.isNotEmpty && b.sets.every((s) => s.completed);

/// One bar per exercise: lime when finished, orange for the current one.
class _Segments extends StatelessWidget {
  const _Segments(this.blocks);
  final List<ExerciseBlock> blocks;

  @override
  Widget build(BuildContext context) {
    final current = blocks.indexWhere((b) => !_blockDone(b));
    return Row(children: [
      for (var i = 0; i < blocks.length; i++) ...[
        if (i > 0) const SizedBox(width: 4),
        Expanded(
          child: Container(
            height: 5,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: _blockDone(blocks[i])
                  ? AppColors.lime
                  : i == current
                      ? AppColors.accent
                      : AppColors.border,
            ),
          ),
        ),
      ],
    ]);
  }
}

class _BlockCard extends ConsumerWidget {
  const _BlockCard({required this.workoutId, required this.order, required this.total, required this.block});
  final int workoutId;
  final int order, total;
  final ExerciseBlock block;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final last = ref.watch(lastPerformanceProvider(block.exercise.id)).value;
    final lastText = last == null
        ? ''
        : last.isEmpty
            ? l10n.lastTimeNone
            : l10n.lastTime(last.map((s) => '${fmtNum(s.weightKg)}×${s.reps}').join('  '));
    final firstOpen = block.sets.indexWhere((s) => !s.completed);
    final done = _blockDone(block);
    const header = TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1, color: AppColors.muted);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Panel(
        radius: 24,
        padding: EdgeInsets.zero,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SizedBox(
            height: 96,
            child: StripeBackground(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xF215171C), Color(0x1A15171C)],
                  ),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
                  Text(l10n.exerciseOf(order + 1, total).toUpperCase(),
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: done ? AppColors.lime : AppColors.accent)),
                  const SizedBox(height: 2),
                  Text(block.exercise.name.toUpperCase(),
                      style: display(30, italic: true), maxLines: 1, overflow: TextOverflow.ellipsis),
                ]),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (lastText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(lastText, style: const TextStyle(fontSize: 12, color: AppColors.textSoft)),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(children: [
                  SizedBox(width: 44, child: Text(l10n.setLabel.toUpperCase(), style: header, textAlign: TextAlign.center)),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('KG', style: header, textAlign: TextAlign.center)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(l10n.reps.toUpperCase(), style: header, textAlign: TextAlign.center)),
                  const SizedBox(width: 92),
                ]),
              ),
              const SizedBox(height: 4),
              for (var i = 0; i < block.sets.length; i++)
                _SetRow(key: ValueKey(block.sets[i].id), index: i + 1, set: block.sets[i], active: i == firstOpen),
              TextButton.icon(
                onPressed: () => ref.read(workoutRepositoryProvider).addSet(workoutId, order),
                icon: const Icon(Icons.add_rounded),
                label: Text(l10n.addSet),
                style: TextButton.styleFrom(foregroundColor: AppColors.textSoft),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _SetRow extends ConsumerStatefulWidget {
  const _SetRow({super.key, required this.index, required this.set, required this.active});
  final int index;
  final WorkoutSet set;
  final bool active;

  @override
  ConsumerState<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends ConsumerState<_SetRow> {
  late final _weight = TextEditingController(text: fmtNum(widget.set.weightKg));
  late final _reps = TextEditingController(text: '${widget.set.reps}');

  @override
  void dispose() {
    _weight.dispose();
    _reps.dispose();
    super.dispose();
  }

  Future<void> _save({bool? completed}) =>
      ref.read(workoutRepositoryProvider).updateSet(
            widget.set.id,
            weightKg: parseNum(_weight.text) ?? 0,
            reps: int.tryParse(_reps.text.trim()) ?? 0,
            completed: completed,
          );

  Future<void> _toggle() async {
    final done = !widget.set.completed;
    await _save(completed: done);
    if (done) {
      final secs = ref.read(restSecondsProvider).value ?? defaultRestSeconds;
      ref.read(restTimerProvider.notifier).start(secs);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final done = widget.set.completed;
    final valueStyle = display(22, color: done ? AppColors.lime : AppColors.text, weight: FontWeight.w700);
    InputDecoration field(String label) => InputDecoration(
          isDense: true,
          hintText: label,
          fillColor: done ? Colors.transparent : AppColors.surfaceHigh,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        );
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: done
            ? const Color(0xFF1B2410)
            : widget.active
                ? const Color(0xFF241811)
                : null,
        borderRadius: BorderRadius.circular(14),
        border: widget.active && !done ? Border.all(color: AppColors.accent, width: 1.5) : null,
      ),
      child: Row(children: [
        SizedBox(
            width: 44,
            child: Text('${widget.index}', textAlign: TextAlign.center, style: display(20, weight: FontWeight.w700))),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: _weight,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: valueStyle,
            decoration: field(l10n.setWeight),
            onChanged: (_) => _save(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: _reps,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: valueStyle,
            decoration: field(l10n.reps),
            onChanged: (_) => _save(),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: l10n.setDone,
          isSelected: done,
          icon: const Icon(Icons.check_rounded),
          style: IconButton.styleFrom(
            fixedSize: const Size(44, 44),
            backgroundColor: done ? AppColors.lime : AppColors.border,
            foregroundColor: done ? AppColors.bg : const Color(0xFF6B7180),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _toggle,
        ),
        IconButton(
          tooltip: l10n.delete,
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.muted),
          onPressed: () => ref.read(workoutRepositoryProvider).removeSet(widget.set.id),
        ),
      ]),
    );
  }
}
