import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/ui/enum_labels.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../goals/data/goals_providers.dart';
import '../data/analyzer_providers.dart';
import '../data/meal_repository.dart';
import '../domain/food_models.dart';

class MealsPage extends ConsumerWidget {
  const MealsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final day = ref.watch(selectedDayProvider);
    final today = DateTime.now();
    final isToday = day == DateTime(today.year, today.month, today.day);
    final hasKey = ref.watch(foodAnalyzerProvider) != null;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navMeals)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addMenu(context, hasKey),
        icon: const Icon(Icons.add),
        label: Text(l10n.mealAdd),
      ),
      body: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => ref.read(selectedDayProvider.notifier).shift(-1)),
          Text(isToday ? l10n.today : fmtDate(day), style: Theme.of(context).textTheme.titleMedium),
          IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: isToday ? null : () => ref.read(selectedDayProvider.notifier).shift(1)),
        ]),
        Expanded(
          child: AsyncBody<List<MealWithItems>>(
            value: ref.watch(dayMealsProvider),
            onRetry: () => ref.invalidate(dayMealsProvider),
            builder: (meals) => ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
              children: [
                _TotalsCard(meals),
                const SizedBox(height: 12),
                if (!hasKey) const _AiDisabledCard(),
                if (meals.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 32),
                    child: EmptyState(icon: Icons.restaurant, message: l10n.mealsEmpty),
                  ),
                for (final m in meals) _MealTile(m),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  void _addMenu(BuildContext context, bool hasKey) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          for (final (src, icon, label) in [
            (ImageSource.camera, Icons.photo_camera_outlined, l10n.mealFromCamera),
            (ImageSource.gallery, Icons.photo_library_outlined, l10n.mealFromGallery),
          ])
            ListTile(
              leading: Icon(icon),
              title: Text(label),
              subtitle: hasKey ? null : Text(l10n.aiNeedsKey),
              enabled: hasKey,
              onTap: () {
                Navigator.pop(ctx);
                _pick(context, src);
              },
            ),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: Text(l10n.addManually),
            onTap: () {
              Navigator.pop(ctx);
              context.push('/meals/review');
            },
          ),
        ]),
      ),
    );
  }

  Future<void> _pick(BuildContext context, ImageSource source) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final x = await ImagePicker().pickImage(source: source, maxWidth: 2048);
      if (x == null || !context.mounted) return;
      context.push('/meals/review', extra: await x.readAsBytes());
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.photoError)));
    }
  }
}

class _AiDisabledCard extends StatelessWidget {
  const _AiDisabledCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: ListTile(
        leading: const Icon(Icons.auto_awesome_outlined),
        title: Text(l10n.aiDisabledTitle),
        subtitle: Text(l10n.aiDisabledBody),
        trailing: TextButton(
            onPressed: () => context.push('/settings/api-key'), child: Text(l10n.configureKey)),
      ),
    );
  }
}

class _TotalsCard extends ConsumerWidget {
  const _TotalsCard(this.meals);
  final List<MealWithItems> meals;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final goal = ref.watch(goalsProvider).value?.dailyCalories;
    final t = Totals(
      kcal: meals.fold(0.0, (s, m) => s + m.totals.kcal),
      proteinG: meals.fold(0.0, (s, m) => s + m.totals.proteinG),
      carbsG: meals.fold(0.0, (s, m) => s + m.totals.carbsG),
      fatG: meals.fold(0.0, (s, m) => s + m.totals.fatG),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(goal == null ? '${t.kcal.round()} kcal' : '${t.kcal.round()} / $goal kcal',
              style: Theme.of(context).textTheme.headlineSmall),
          if (goal != null) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
                value: (t.kcal / goal).clamp(0, 1).toDouble(),
                minHeight: 10,
                borderRadius: BorderRadius.circular(8)),
          ],
          const SizedBox(height: 8),
          Text(l10n.macrosLine(fmtNum(t.proteinG.roundToDouble()), fmtNum(t.carbsG.roundToDouble()),
              fmtNum(t.fatG.roundToDouble()))),
        ]),
      ),
    );
  }
}

class _MealTile extends ConsumerWidget {
  const _MealTile(this.m);
  final MealWithItems m;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Dismissible(
      key: ValueKey(m.meal.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Theme.of(context).colorScheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete_outline),
      ),
      onDismissed: (_) => ref.read(mealRepositoryProvider).delete(m.meal.id),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text('${m.meal.mealType.label(l10n)} · ${DateFormat.Hm().format(m.meal.eatenAt)}'),
        subtitle: Text(m.items.map((i) => i.name).join(', ')),
        trailing: Text('${m.totals.kcal.round()} kcal', style: Theme.of(context).textTheme.titleSmall),
      ),
    );
  }
}
