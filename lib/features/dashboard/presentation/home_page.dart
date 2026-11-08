import 'package:flutter/material.dart';

import '../../../core/widgets/placeholder_page.dart';
import '../../../l10n/gen/app_localizations.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PlaceholderPage(title: l10n.navHome, icon: Icons.home_outlined, message: l10n.homeSoon);
  }
}
