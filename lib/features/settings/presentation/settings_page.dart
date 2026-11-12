import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/settings_repository.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final userName = ref.watch(userNameProvider).value;
    final userGoal = ref.watch(userGoalProvider).value;

    final goalLabel = switch (userGoal) {
      'build_muscle' => 'Ganar masa muscular',
      'lose_weight' => 'Perder grasa',
      'strength' => 'Ganar fuerza',
      'maintain' => 'Salud y forma',
      _ => null,
    };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navSettings)),
      body: ListView(children: [
        if (userName != null && userName.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.person_rounded, color: AppColors.accent, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      userName.toUpperCase(),
                      style: display(22, weight: FontWeight.w700),
                    ),
                    if (goalLabel != null)
                      Text(
                        goalLabel,
                        style: const TextStyle(fontSize: 12, color: AppColors.muted),
                      ),
                  ]),
                ),
                TextButton(
                  onPressed: () => context.push('/onboarding'),
                  child: const Text('Editar'),
                ),
              ]),
            ),
          ),
          const Divider(height: 1),
        ],
        ListTile(
          leading: const Icon(Icons.flag_outlined),
          title: Text(l10n.goalsTitle),
          subtitle: Text(l10n.goalsSubtitle),
          onTap: () => context.push('/goals'),
        ),
        ListTile(
          leading: const Icon(Icons.notifications_outlined),
          title: Text(l10n.remindersTitle),
          subtitle: Text(l10n.remindersSubtitle),
          onTap: () => context.push('/reminders'),
        ),
        ListTile(
          leading: const Icon(Icons.backup_outlined),
          title: const Text('Copia de seguridad y datos'),
          subtitle: const Text('Exportar e importar tus datos en JSON o CSV'),
          onTap: () => context.push('/settings/backup'),
        ),
        ListTile(
          leading: const Icon(Icons.auto_awesome_outlined),
          title: Text(l10n.apiKeyTitle),
          subtitle: Text(l10n.apiKeySubtitle),
          onTap: () => context.push('/settings/api-key'),
        ),
      ]),
    );
  }
}
