import 'package:flutter/material.dart';

import '../../../core/widgets/placeholder_page.dart';
import '../../../l10n/gen/app_localizations.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PlaceholderPage(title: l10n.navSettings, icon: Icons.settings, message: l10n.settingsSoon);
  }
}
