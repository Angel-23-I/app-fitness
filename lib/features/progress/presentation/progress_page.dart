import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/fit_widgets.dart';
import '../../../l10n/gen/app_localizations.dart';
import 'measures_tab.dart';
import 'photos_tab.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            ScreenHeader(title: l10n.navProgress),
            Container(
              margin: const EdgeInsets.fromLTRB(20, 4, 20, 4),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: TabBar(tabs: [Tab(text: l10n.tabMeasures, height: 40), Tab(text: l10n.tabPhotos, height: 40)]),
            ),
            const Expanded(child: TabBarView(children: [MeasuresTab(), PhotosTab()])),
          ]),
        ),
      ),
    );
  }
}
