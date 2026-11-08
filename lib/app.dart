import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'l10n/gen/app_localizations.dart';

class FitTrackApp extends ConsumerWidget {
  const FitTrackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
        onGenerateTitle: (c) => AppLocalizations.of(c).appName,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        routerConfig: ref.watch(routerProvider),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
      );
}
