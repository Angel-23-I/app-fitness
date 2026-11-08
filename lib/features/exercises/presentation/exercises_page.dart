import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/enums.dart';
import '../../../core/ui/enum_labels.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/exercise_repository.dart';

/// Exercise catalog. In [pickMode] it lets the user select several and pops them as a list.
class ExercisesPage extends ConsumerStatefulWidget {
  const ExercisesPage({super.key, this.pickMode = false});
  final bool pickMode;

  @override
  ConsumerState<ExercisesPage> createState() => _ExercisesPageState();
}

class _ExercisesPageState extends ConsumerState<ExercisesPage> {
  String _query = '';
  MuscleGroup? _muscle;
  final _selected = <int, Exercise>{};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(exercisesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(widget.pickMode ? l10n.exercisesPickTitle : l10n.exercisesTitle)),
      floatingActionButton: widget.pickMode && _selected.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => context.pop(_selected.values.toList()),
              icon: const Icon(Icons.check),
              label: Text(l10n.exercisesAddSelected(_selected.length)),
            )
          : FloatingActionButton(
              tooltip: l10n.exerciseNew,
              onPressed: () => _createDialog(context),
              child: const Icon(Icons.add),
            ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.exercisesSearch,
              ),
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
            ),
          ),
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                ChoiceChip(
                    label: Text(l10n.exercisesAll),
                    selected: _muscle == null,
                    onSelected: (_) => setState(() => _muscle = null)),
                for (final m in MuscleGroup.values)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: ChoiceChip(
                        label: Text(m.label(l10n)),
                        selected: _muscle == m,
                        onSelected: (_) => setState(() => _muscle = m)),
                  ),
              ],
            ),
          ),
          Expanded(
            child: AsyncBody<List<Exercise>>(
              value: async,
              onRetry: () => ref.invalidate(exercisesProvider),
              builder: (all) {
                final list = all
                    .where((e) =>
                        (_muscle == null || e.muscleGroup == _muscle) &&
                        e.name.toLowerCase().contains(_query))
                    .toList();
                if (list.isEmpty) {
                  return EmptyState(icon: Icons.search_off, message: l10n.exercisesEmpty);
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: list.length,
                  itemBuilder: (_, i) => _tile(list[i], l10n),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(Exercise e, AppLocalizations l10n) {
    final subtitle = '${e.muscleGroup.label(l10n)} · ${e.equipment.label(l10n)}'
        '${e.isCustom ? ' · ${l10n.exerciseCustom}' : ''}';
    if (widget.pickMode) {
      final on = _selected.containsKey(e.id);
      return CheckboxListTile(
        value: on,
        title: Text(e.name),
        subtitle: Text(subtitle),
        onChanged: (v) => setState(() => v! ? _selected[e.id] = e : _selected.remove(e.id)),
      );
    }
    return ListTile(
      title: Text(e.name),
      subtitle: Text(subtitle),
      trailing: e.isCustom
          ? IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: l10n.delete,
              onPressed: () async {
                final ok = await ref.read(exerciseRepositoryProvider).delete(e);
                if (!ok && mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(l10n.exerciseInUse)));
                }
              },
            )
          : null,
    );
  }

  Future<void> _createDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final name = TextEditingController();
    var muscle = MuscleGroup.chest;
    var equip = Equipment.barbell;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(l10n.exerciseNew),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                  controller: name,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(labelText: l10n.exerciseName)),
              const SizedBox(height: 12),
              DropdownButtonFormField<MuscleGroup>(
                initialValue: muscle,
                decoration: InputDecoration(labelText: l10n.exerciseMuscle),
                items: [
                  for (final m in MuscleGroup.values)
                    DropdownMenuItem(value: m, child: Text(m.label(l10n)))
                ],
                onChanged: (v) => setS(() => muscle = v!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Equipment>(
                initialValue: equip,
                decoration: InputDecoration(labelText: l10n.exerciseEquipment),
                items: [
                  for (final e in Equipment.values)
                    DropdownMenuItem(value: e, child: Text(e.label(l10n)))
                ],
                onChanged: (v) => setS(() => equip = v!),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.save)),
          ],
        ),
      ),
    );
    if (ok == true && name.text.trim().isNotEmpty) {
      await ref.read(exerciseRepositoryProvider).add(name.text, muscle, equip);
    }
    name.dispose();
  }
}
