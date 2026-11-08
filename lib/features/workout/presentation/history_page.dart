import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/format.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/workout_repository.dart';
import '../domain/workout_models.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.historyTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events_outlined),
            tooltip: l10n.recordsTitle,
            onPressed: () => context.push('/records'),
          ),
        ],
      ),
      body: AsyncBody<List<WorkoutSummary>>(
        value: ref.watch(historyProvider),
        onRetry: () => ref.invalidate(historyProvider),
        isEmpty: (l) => l.isEmpty,
        empty: EmptyState(icon: Icons.history, message: l10n.historyEmpty),
        builder: (list) => ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final s = list[i];
            return Card(
              child: ListTile(
                title: Text(s.workout.name),
                subtitle: Text('${fmtDateTime(s.workout.startedAt)}\n'
                    '${l10n.durationMin(s.duration.inMinutes)} · ${l10n.workoutSummary(s.sets, fmtNum(s.volumeKg))}'),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/history/${s.workout.id}'),
              ),
            );
          },
        ),
      ),
    );
  }
}
