import 'package:flutter/material.dart';

import '../../../core/widgets/placeholder_page.dart';
import '../../../l10n/gen/app_localizations.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PlaceholderPage(title: l10n.navProgress, icon: Icons.show_chart, message: l10n.progressSoon);
  }
}
