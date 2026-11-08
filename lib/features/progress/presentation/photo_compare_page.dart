import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/body_repository.dart';
import 'photos_tab.dart';

class PhotoComparePage extends ConsumerWidget {
  const PhotoComparePage({super.key, required this.idA, required this.idB});
  final int idA, idB;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.comparisonTitle)),
      body: AsyncBody<List<ProgressPhoto>>(
        value: ref.watch(photosProvider),
        onRetry: () => ref.invalidate(photosProvider),
        builder: (all) {
          final pair = all.where((p) => p.id == idA || p.id == idB).toList()
            ..sort((a, b) => a.date.compareTo(b.date)); // older on the left
          if (pair.length != 2) {
            return EmptyState(icon: Icons.photo_outlined, message: l10n.photoMissing);
          }
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              for (final p in pair)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(children: [
                      Expanded(
                          child: ClipRRect(
                              borderRadius: BorderRadius.circular(12), child: SizedBox.expand(child: PhotoImage(p)))),
                      const SizedBox(height: 8),
                      Text(fmtDate(p.date), style: Theme.of(context).textTheme.titleSmall),
                    ]),
                  ),
                ),
            ]),
          );
        },
      ),
    );
  }
}
