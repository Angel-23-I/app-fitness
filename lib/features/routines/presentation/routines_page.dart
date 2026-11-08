import 'package:flutter/material.dart';

import '../../../core/widgets/placeholder_page.dart';
import '../../../l10n/gen/app_localizations.dart';

class RoutinesPage extends StatelessWidget {
  const RoutinesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PlaceholderPage(title: l10n.navRoutines, icon: Icons.fitness_center, message: l10n.routinesSoon);
  }
}
