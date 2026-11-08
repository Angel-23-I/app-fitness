import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/gen/app_localizations.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navSettings)),
      body: ListView(children: [
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
      ]),
    );
  }
}
