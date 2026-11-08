import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/workout_repository.dart';
import '../domain/pr_calculator.dart';

class RecordsPage extends ConsumerWidget {
  const RecordsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.recordsTitle)),
      body: AsyncBody<List<(Exercise, PersonalRecord)>>(
        value: ref.watch(recordsProvider),
        onRetry: () => ref.invalidate(recordsProvider),
        isEmpty: (l) => l.isEmpty,
        empty: EmptyState(icon: Icons.emoji_events_outlined, message: l10n.recordsEmpty),
        builder: (list) => ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final (e, pr) = list[i];
            final bodyweight = pr.maxWeight == 0;
            return Card(
              child: ListTile(
                title: Text(e.name),
                subtitle: Text(bodyweight
                    ? l10n.recordMaxReps(pr.maxReps)
                    : '${l10n.recordMaxWeight}: ${fmtNum(pr.maxWeight)} kg · ${l10n.record1RM}: ${fmtNum(pr.best1RM)} kg'),
                leading: const Icon(Icons.emoji_events),
              ),
            );
          },
        ),
      ),
    );
  }
}
