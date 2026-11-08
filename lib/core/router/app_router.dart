import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/dashboard/presentation/home_page.dart';
import '../../features/exercises/presentation/exercises_page.dart';
import '../../features/routines/presentation/routine_edit_page.dart';
import '../../features/workout/presentation/history_detail_page.dart';
import '../../features/workout/presentation/history_page.dart';
import '../../features/workout/presentation/records_page.dart';
import '../../features/workout/presentation/workout_page.dart';
import '../../features/nutrition/presentation/meals_page.dart';
import '../../features/progress/presentation/progress_page.dart';
import '../../features/routines/presentation/routines_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../l10n/gen/app_localizations.dart';

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
        GoRoute(path: '/history', builder: (_, _) => const HistoryPage()),
        GoRoute(
          path: '/history/:id',
          builder: (_, s) => HistoryDetailPage(workoutId: int.parse(s.pathParameters['id']!)),
        ),
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
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: l10n.navHome),
          NavigationDestination(icon: const Icon(Icons.fitness_center_outlined), selectedIcon: const Icon(Icons.fitness_center), label: l10n.navRoutines),
          NavigationDestination(icon: const Icon(Icons.show_chart), label: l10n.navProgress),
          NavigationDestination(icon: const Icon(Icons.restaurant_outlined), selectedIcon: const Icon(Icons.restaurant), label: l10n.navMeals),
          NavigationDestination(icon: const Icon(Icons.settings_outlined), selectedIcon: const Icon(Icons.settings), label: l10n.navSettings),
        ],
      ),
    );
  }
}
