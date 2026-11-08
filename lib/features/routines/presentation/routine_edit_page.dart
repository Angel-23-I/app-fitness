import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/routine_repository.dart';
import '../domain/routine_models.dart';

class RoutineEditPage extends ConsumerStatefulWidget {
  const RoutineEditPage({super.key, this.routineId});
  final int? routineId;

  @override
  ConsumerState<RoutineEditPage> createState() => _RoutineEditPageState();
}

class _RoutineEditPageState extends ConsumerState<RoutineEditPage> {
  final _name = TextEditingController();
  final _items = <RoutineItem>[];
  Object? _error;
  var _loading = true;
  var _showErrors = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.routineId == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final d = await ref.read(routineRepositoryProvider).load(widget.routineId!);
      if (!mounted) return;
      setState(() {
        if (d != null) {
          _name.text = d.routine.name;
          _items.addAll(d.items);
        }
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _addExercises() async {
    final picked = await context.push<List<Exercise>>('/exercises?pick=1');
    if (picked == null) return;
    final have = _items.map((e) => e.exercise.id).toSet();
    setState(() => _items.addAll(
        [for (final e in picked) if (!have.contains(e.id)) RoutineItem(e)]));
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty || _items.isEmpty) {
      setState(() => _showErrors = true);
      return;
    }
    await ref
        .read(routineRepositoryProvider)
        .save(id: widget.routineId, name: _name.text, items: _items);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.routineId == null ? l10n.routineNew : l10n.routineEdit),
        actions: [TextButton(onPressed: _save, child: Text(l10n.save))],
      ),
      body: _error != null
          ? ErrorState(error: _error!)
          : _loading
              ? const Center(child: CircularProgressIndicator())
              : _form(l10n),
    );
  }

  Widget _form(AppLocalizations l10n) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _name,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: l10n.routineName,
            errorText: _showErrors && _name.text.trim().isEmpty ? l10n.routineNameRequired : null,
          ),
        ),
      ),
      Expanded(
        child: _items.isEmpty
            ? EmptyState(
                icon: Icons.fitness_center,
                message: _showErrors ? l10n.routineNoExercises : l10n.routineAddExercises,
              )
            : ReorderableListView.builder(
                buildDefaultDragHandles: false,
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: _items.length,
                onReorderItem: (from, to) =>
                    setState(() => _items.insert(to, _items.removeAt(from))),
                itemBuilder: (_, i) => _ItemTile(
                  key: ValueKey(_items[i].exercise.id),
                  index: i,
                  item: _items[i],
                  onChanged: (v) => setState(() => _items[i] = v),
                  onRemove: () => setState(() => _items.removeAt(i)),
                ),
              ),
      ),
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: _addExercises,
              icon: const Icon(Icons.add),
              label: Text(l10n.routineAddExercises),
            ),
          ),
        ),
      ),
    ]);
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({
    super.key,
    required this.index,
    required this.item,
    required this.onChanged,
    required this.onRemove,
  });

  final int index;
  final RoutineItem item;
  final ValueChanged<RoutineItem> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      leading: ReorderableDragStartListener(index: index, child: const Icon(Icons.drag_handle)),
      title: Text(item.exercise.name),
      subtitle: Row(children: [
        Text('${l10n.sets} '),
        _Step(item.sets, 1, 10, (v) => onChanged(item.copyWith(sets: v))),
        const SizedBox(width: 12),
        Text('${l10n.reps} '),
        _Step(item.reps, 1, 50, (v) => onChanged(item.copyWith(reps: v))),
      ]),
      trailing: IconButton(
          icon: const Icon(Icons.close), tooltip: l10n.delete, onPressed: onRemove),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step(this.value, this.min, this.max, this.onChanged);
  final int value, min, max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: value > min ? () => onChanged(value - 1) : null,
        ),
        Text('$value', style: Theme.of(context).textTheme.titleSmall),
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.add_circle_outline),
          onPressed: value < max ? () => onChanged(value + 1) : null,
        ),
      ]);
}
