import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/db/enums.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/ui/enum_labels.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/fit_widgets.dart';
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
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => _addMenu(context, hasKey),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.mealAdd),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          ScreenHeader(title: l10n.navMeals, actions: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                    tooltip: MaterialLocalizations.of(context).previousPageTooltip,
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: () => ref.read(selectedDayProvider.notifier).shift(-1)),
                Text(isToday ? l10n.today : DateFormat.MMMd('es').format(day),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                IconButton(
                    tooltip: MaterialLocalizations.of(context).nextPageTooltip,
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: isToday ? null : () => ref.read(selectedDayProvider.notifier).shift(1)),
              ]),
            ),
          ]),
          Expanded(
            child: AsyncBody<List<MealWithItems>>(
              value: ref.watch(dayMealsProvider),
              onRetry: () => ref.invalidate(dayMealsProvider),
              builder: (meals) => ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
                children: [
                  _TotalsCard(meals),
                  const SizedBox(height: 14),
                  if (hasKey)
                    _ScanButton(onTap: () => _pick(context, ImageSource.camera))
                  else
                    const _AiDisabledCard(),
                  const SizedBox(height: 14),
                  if (meals.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: EmptyState(icon: Icons.restaurant_rounded, message: l10n.mealsEmpty),
                    ),
                  for (final m in meals)
                    Padding(padding: const EdgeInsets.only(bottom: 10), child: _MealTile(m)),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  void _addMenu(BuildContext context, bool hasKey) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      useRootNavigator: true,
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

class _ScanButton extends StatelessWidget {
  const _ScanButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: AppColors.lime,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.photo_camera_rounded, color: AppColors.lime, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l10n.scanMealTitle,
                    style: const TextStyle(color: AppColors.bg, fontWeight: FontWeight.w700, fontSize: 16)),
                Text(l10n.scanMealSubtitle, style: const TextStyle(color: Color(0xFF2E3A10), fontSize: 12)),
              ]),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.bg),
          ]),
        ),
      ),
    );
  }
}

class _AiDisabledCard extends StatelessWidget {
  const _AiDisabledCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Panel(
      radius: 20,
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      child: Row(children: [
        const Icon(Icons.auto_awesome_rounded, color: AppColors.lime),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l10n.aiDisabledTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(l10n.aiDisabledBody, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ]),
        ),
        TextButton(onPressed: () => context.push('/settings/api-key'), child: Text(l10n.configureKey)),
      ]),
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
    final kcal = t.kcal.round();
    final left = goal == null ? null : goal - kcal;
    // Bars show each macro's share of the day's calories (4 / 4 / 9 kcal per gram).
    final macroKcal = t.proteinG * 4 + t.carbsG * 4 + t.fatG * 9;
    double share(double k) => macroKcal == 0 ? 0 : k / macroKcal;
    final macros = [
      (l10n.macroProtein, t.proteinG, share(t.proteinG * 4), AppColors.accent),
      (l10n.macroCarbs, t.carbsG, share(t.carbsG * 4), AppColors.sky),
      (l10n.macroFat, t.fatG, share(t.fatG * 9), AppColors.lime),
    ];
    return Panel(
      child: Row(children: [
        ActivityRings(
          size: 140,
          stroke: 12,
          rings: [Ring(goal == null ? (kcal > 0 ? 1 : 0) : kcal / goal, AppColors.accent, track: AppColors.surfaceHigh)],
          semanticsLabel: goal == null ? '$kcal kcal' : '$kcal / $goal kcal',
          center: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(fmtThousands(left?.abs() ?? kcal), style: display(36)),
            Text(left == null ? l10n.kcalEaten : (left >= 0 ? l10n.kcalLeft : l10n.kcalOver),
                style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          ]),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (final (name, grams, value, color) in macros) ...[
              Row(children: [
                Expanded(child: Text(name, style: const TextStyle(fontSize: 12, color: AppColors.textSoft))),
                Text('${fmtNum(grams.roundToDouble())} g',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 5),
              ThinBar(value: value, color: color),
              const SizedBox(height: 12),
            ],
          ]),
        ),
      ]),
    );
  }
}

const _mealColors = {
  MealType.breakfast: AppColors.gold,
  MealType.lunch: AppColors.accent,
  MealType.dinner: AppColors.sky,
  MealType.snack: AppColors.lime,
};

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
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete_outline_rounded),
      ),
      onDismissed: (_) => ref.read(mealRepositoryProvider).delete(m.meal.id),
      child: Panel(
        radius: 18,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(children: [
          Container(
            width: 10,
            height: 40,
            decoration: BoxDecoration(
              color: _mealColors[m.meal.mealType] ?? AppColors.border,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${m.meal.mealType.label(l10n)} · ${DateFormat.Hm().format(m.meal.eatenAt)}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 2),
              Text(m.items.map((i) => i.name).join(', '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            ]),
          ),
          const SizedBox(width: 8),
          BigValue(fmtThousands(m.totals.kcal), unit: 'kcal', size: 22),
        ]),
      ),
    );
  }
}
