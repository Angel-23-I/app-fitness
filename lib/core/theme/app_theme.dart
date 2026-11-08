import 'package:flutter/material.dart';

class AppTheme {
  static const _seed = Color(0xFFFF6B35);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: _seed, brightness: brightness),
        visualDensity: VisualDensity.standard,
        cardTheme: const CardThemeData(margin: EdgeInsets.zero),
        inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
      );
}
