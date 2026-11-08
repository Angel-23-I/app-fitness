import 'package:flutter/material.dart';

import '../../../core/widgets/placeholder_page.dart';
import '../../../l10n/gen/app_localizations.dart';

class MealsPage extends StatelessWidget {
  const MealsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PlaceholderPage(title: l10n.navMeals, icon: Icons.restaurant, message: l10n.mealsSoon);
  }
}
