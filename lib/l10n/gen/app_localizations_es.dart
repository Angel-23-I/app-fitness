// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'FitTrack';

  @override
  String get navHome => 'Inicio';

  @override
  String get navRoutines => 'Rutinas';

  @override
  String get navProgress => 'Progreso';

  @override
  String get navMeals => 'Comida';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get emptyTitle => 'Aún no hay nada aquí';

  @override
  String get errorTitle => 'Algo salió mal';

  @override
  String get retry => 'Reintentar';

  @override
  String get homeSoon => 'Tu resumen del día aparecerá aquí.';

  @override
  String get routinesSoon => 'Crea tu primera rutina para empezar a entrenar.';

  @override
  String get progressSoon =>
      'Registra tu peso y medidas para ver tu evolución.';

  @override
  String get mealsSoon => 'Registra tus comidas del día.';

  @override
  String get settingsSoon =>
      'Aquí configurarás tus metas, recordatorios y la clave de API.';
}
