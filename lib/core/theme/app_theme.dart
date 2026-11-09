import 'package:flutter/material.dart';

/// "Energía nocturna" palette: near-black ground, orange as the action color,
/// lime for achievements, sky and gold only for data.
abstract final class AppColors {
  static const bg = Color(0xFF0B0C0F);
  static const surface = Color(0xFF15171C);
  static const surfaceHigh = Color(0xFF232631);
  static const border = Color(0xFF2A2E37);
  static const text = Color(0xFFF4F5F7);
  static const textSoft = Color(0xFFC9CDD4);
  static const muted = Color(0xFF9AA0AC);
  static const accent = Color(0xFFFF6B2C);
  static const lime = Color(0xFFC8F04A);
  static const sky = Color(0xFF6EC1FF);
  static const gold = Color(0xFFFFB020);
  static const danger = Color(0xFFFF5A5F);
}

/// Display type: condensed, bold, used for titles and big numbers.
TextStyle display(double size, {Color? color, bool italic = false, FontWeight weight = FontWeight.w800}) =>
    TextStyle(
      fontFamily: 'BarlowCondensed',
      fontSize: size,
      fontWeight: weight,
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      height: 1.0,
      color: color ?? AppColors.text,
    );

class AppTheme {
  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      primary: AppColors.accent,
      onPrimary: AppColors.bg,
      primaryContainer: Color(0xFF3A1D10),
      onPrimaryContainer: Color(0xFFFFD9C8),
      secondary: AppColors.lime,
      onSecondary: AppColors.bg,
      secondaryContainer: Color(0xFF26300F),
      onSecondaryContainer: AppColors.lime,
      tertiary: AppColors.sky,
      onTertiary: AppColors.bg,
      error: AppColors.danger,
      onError: AppColors.bg,
      errorContainer: Color(0xFF4A1416),
      onErrorContainer: Color(0xFFFFDAD6),
      surface: AppColors.bg,
      onSurface: AppColors.text,
      onSurfaceVariant: AppColors.muted,
      surfaceContainerLowest: AppColors.bg,
      surfaceContainerLow: AppColors.surface,
      surfaceContainer: AppColors.surface,
      surfaceContainerHigh: AppColors.surfaceHigh,
      surfaceContainerHighest: AppColors.surfaceHigh,
      outline: Color(0xFF4A505C),
      outlineVariant: AppColors.border,
    );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme, brightness: Brightness.dark);
    final text = base.textTheme.copyWith(
      displayLarge: display(56),
      displayMedium: display(46),
      displaySmall: display(38),
      headlineLarge: display(34, italic: true),
      headlineMedium: display(30),
      headlineSmall: display(26, weight: FontWeight.w700),
      titleLarge: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      titleSmall: base.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      labelLarge: base.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
    ).apply(bodyColor: AppColors.text, displayColor: AppColors.text);
    final rounded16 = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      textTheme: text,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: display(28, italic: true),
      ),
      cardTheme: CardThemeData(
        margin: EdgeInsets.zero,
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: rounded16,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: rounded16,
          side: const BorderSide(color: AppColors.border),
          foregroundColor: AppColors.text,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(textStyle: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.bg,
        elevation: 0,
        shape: rounded16,
        extendedTextStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceHigh,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.muted),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.text,
        side: const BorderSide(color: AppColors.border),
        shape: const StadiumBorder(),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSoft),
        secondaryLabelStyle: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.bg),
        checkmarkColor: AppColors.bg,
        showCheckmark: false,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.muted,
          selectedBackgroundColor: AppColors.text,
          selectedForegroundColor: AppColors.bg,
          side: const BorderSide(color: AppColors.border),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(12)),
        labelColor: AppColors.text,
        unselectedLabelColor: AppColors.muted,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        splashBorderRadius: BorderRadius.circular(12),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.lime,
        linearTrackColor: AppColors.surfaceHigh,
      ),
      listTileTheme: const ListTileThemeData(iconColor: AppColors.muted),
      dividerTheme: const DividerThemeData(color: AppColors.border),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        dragHandleColor: AppColors.border,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surfaceHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.text,
        contentTextStyle: const TextStyle(color: AppColors.bg, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? AppColors.bg : AppColors.muted),
        trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? AppColors.lime : AppColors.surfaceHigh),
      ),
    );
  }
}
