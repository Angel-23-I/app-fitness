import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/dashboard/presentation/home_page.dart';
import '../../features/exercises/presentation/exercises_page.dart';
import '../../features/routines/presentation/routine_edit_page.dart';
import '../../features/workout/presentation/history_detail_page.dart';
import '../../features/workout/presentation/history_page.dart';
import '../../features/workout/presentation/records_page.dart';
import '../../features/workout/domain/workout_models.dart';
import '../../features/workout/presentation/workout_done_page.dart';
import '../../features/workout/presentation/workout_page.dart';
import '../../features/progress/presentation/photo_compare_page.dart';
import '../../features/goals/presentation/goals_page.dart';
import '../../features/goals/presentation/reminders_page.dart';
import '../../features/nutrition/presentation/meal_review_page.dart';
import '../../features/nutrition/presentation/meals_page.dart';
import '../../features/settings/presentation/api_key_page.dart';
import '../../features/progress/presentation/progress_page.dart';
import '../../features/routines/presentation/routines_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../l10n/gen/app_localizations.dart';
import '../theme/app_theme.dart';

final routerProvider = Provider<GoRouter>((ref) => createRouter());

GoRouter createRouter() => GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/exercises',
          builder: (_, s) => ExercisesPage(pickMode: s.uri.queryParameters['pick'] == '1'),
        ),
        GoRoute(
          path: '/routines/edit',
          builder: (_, s) =>
              RoutineEditPage(routineId: int.tryParse(s.uri.queryParameters['id'] ?? '')),
        ),
        GoRoute(
          path: '/workout/:id',
          builder: (_, s) => WorkoutPage(workoutId: int.parse(s.pathParameters['id']!)),
        ),
        GoRoute(
          path: '/workout-done',
          redirect: (_, s) => s.extra is WorkoutResult ? null : '/',
          builder: (_, s) => WorkoutDonePage(result: s.extra! as WorkoutResult),
        ),
        GoRoute(path: '/history', builder: (_, _) => const HistoryPage()),
        GoRoute(
          path: '/history/:id',
          builder: (_, s) => HistoryDetailPage(workoutId: int.parse(s.pathParameters['id']!)),
        ),
        GoRoute(
          path: '/progress/compare',
          builder: (_, s) => PhotoComparePage(
            idA: int.parse(s.uri.queryParameters['a']!),
            idB: int.parse(s.uri.queryParameters['b']!),
          ),
        ),
        GoRoute(
          path: '/meals/review',
          builder: (_, s) => MealReviewPage(imageBytes: s.extra as Uint8List?),
        ),
        GoRoute(path: '/settings/api-key', builder: (_, _) => const ApiKeyPage()),
        GoRoute(path: '/goals', builder: (_, _) => const GoalsPage()),
        GoRoute(path: '/reminders', builder: (_, _) => const RemindersPage()),
        GoRoute(path: '/records', builder: (_, _) => const RecordsPage()),
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => _NavShell(shell: shell),
          branches: [
            _branch('/', const HomePage()),
            _branch('/routines', const RoutinesPage()),
            _branch('/progress', const ProgressPage()),
            _branch('/meals', const MealsPage()),
            _branch('/settings', const SettingsPage()),
          ],
        ),
      ],
    );

StatefulShellBranch _branch(String path, Widget page) => StatefulShellBranch(
      routes: [GoRoute(path: path, builder: (_, _) => page)],
    );

class _NavShell extends StatelessWidget {
  const _NavShell({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = [
      (Icons.home_rounded, l10n.navHome),
      (Icons.fitness_center_rounded, l10n.navRoutines),
      (Icons.trending_up_rounded, l10n.navProgress),
      (Icons.restaurant_rounded, l10n.navMeals),
      (Icons.tune_rounded, l10n.navSettings),
    ];
    return Scaffold(
      body: shell,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Container(
            height: 68,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              for (var i = 0; i < items.length; i++)
                _NavItem(
                  icon: items[i].$1,
                  label: items[i].$2,
                  selected: i == shell.currentIndex,
                  onTap: () => shell.goBranch(i, initialLocation: i == shell.currentIndex),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Floating-bar tab: the selected one grows into an orange pill with its label.
class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        label: label,
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            height: 44,
            constraints: const BoxConstraints(minWidth: 44),
            padding: EdgeInsets.symmetric(horizontal: selected ? 14 : 10),
            decoration: BoxDecoration(
              color: selected ? AppColors.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 22, color: selected ? AppColors.bg : AppColors.muted),
              if (selected) ...[
                const SizedBox(width: 6),
                Text(label,
                    style: const TextStyle(color: AppColors.bg, fontWeight: FontWeight.w700, fontSize: 13)),
              ],
            ]),
          ),
        ),
      );
}
