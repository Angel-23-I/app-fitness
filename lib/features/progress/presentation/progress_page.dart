import 'package:flutter/material.dart';

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
        appBar: AppBar(
          title: Text(l10n.navProgress),
          bottom: TabBar(tabs: [Tab(text: l10n.tabMeasures), Tab(text: l10n.tabPhotos)]),
        ),
        body: const TabBarView(children: [MeasuresTab(), PhotosTab()]),
      ),
    );
  }
}
