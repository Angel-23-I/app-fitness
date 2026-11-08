import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('es')];

  /// No description provided for @appName.
  ///
  /// In es, this message translates to:
  /// **'FitTrack'**
  String get appName;

  /// No description provided for @navHome.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get navHome;

  /// No description provided for @navRoutines.
  ///
  /// In es, this message translates to:
  /// **'Rutinas'**
  String get navRoutines;

  /// No description provided for @navProgress.
  ///
  /// In es, this message translates to:
  /// **'Progreso'**
  String get navProgress;

  /// No description provided for @navMeals.
  ///
  /// In es, this message translates to:
  /// **'Comida'**
  String get navMeals;

  /// No description provided for @navSettings.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get navSettings;

  /// No description provided for @emptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay nada aquí'**
  String get emptyTitle;

  /// No description provided for @errorTitle.
  ///
  /// In es, this message translates to:
  /// **'Algo salió mal'**
  String get errorTitle;

  /// No description provided for @retry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In es, this message translates to:
  /// **'Borrar'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get edit;

  /// No description provided for @homeSoon.
  ///
  /// In es, this message translates to:
  /// **'Tu resumen del día aparecerá aquí.'**
  String get homeSoon;

  /// No description provided for @tabMeasures.
  ///
  /// In es, this message translates to:
  /// **'Medidas'**
  String get tabMeasures;

  /// No description provided for @tabPhotos.
  ///
  /// In es, this message translates to:
  /// **'Fotos'**
  String get tabPhotos;

  /// No description provided for @range1m.
  ///
  /// In es, this message translates to:
  /// **'1 mes'**
  String get range1m;

  /// No description provided for @range3m.
  ///
  /// In es, this message translates to:
  /// **'3 meses'**
  String get range3m;

  /// No description provided for @rangeAll.
  ///
  /// In es, this message translates to:
  /// **'Todo'**
  String get rangeAll;

  /// No description provided for @metricWeight.
  ///
  /// In es, this message translates to:
  /// **'Peso'**
  String get metricWeight;

  /// No description provided for @metricWaist.
  ///
  /// In es, this message translates to:
  /// **'Cintura'**
  String get metricWaist;

  /// No description provided for @metricChest.
  ///
  /// In es, this message translates to:
  /// **'Pecho'**
  String get metricChest;

  /// No description provided for @metricArm.
  ///
  /// In es, this message translates to:
  /// **'Brazo'**
  String get metricArm;

  /// No description provided for @metricThigh.
  ///
  /// In es, this message translates to:
  /// **'Muslo'**
  String get metricThigh;

  /// No description provided for @entryAdd.
  ///
  /// In es, this message translates to:
  /// **'Registrar'**
  String get entryAdd;

  /// No description provided for @entryDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get entryDate;

  /// No description provided for @entryNeedValue.
  ///
  /// In es, this message translates to:
  /// **'Introduce al menos un valor.'**
  String get entryNeedValue;

  /// No description provided for @measuresEmpty.
  ///
  /// In es, this message translates to:
  /// **'Registra tu peso y medidas para ver tu evolución.'**
  String get measuresEmpty;

  /// No description provided for @chartNeedMore.
  ///
  /// In es, this message translates to:
  /// **'Registra al menos dos mediciones para ver la gráfica.'**
  String get chartNeedMore;

  /// No description provided for @photosEmpty.
  ///
  /// In es, this message translates to:
  /// **'Añade tu primera foto de progreso.'**
  String get photosEmpty;

  /// No description provided for @photoAdd.
  ///
  /// In es, this message translates to:
  /// **'Añadir foto'**
  String get photoAdd;

  /// No description provided for @photoCamera.
  ///
  /// In es, this message translates to:
  /// **'Tomar foto'**
  String get photoCamera;

  /// No description provided for @photoGallery.
  ///
  /// In es, this message translates to:
  /// **'Elegir de la galería'**
  String get photoGallery;

  /// No description provided for @photoCompare.
  ///
  /// In es, this message translates to:
  /// **'Comparar'**
  String get photoCompare;

  /// No description provided for @photoCompareHint.
  ///
  /// In es, this message translates to:
  /// **'Elige dos fotos'**
  String get photoCompareHint;

  /// No description provided for @photoCompareView.
  ///
  /// In es, this message translates to:
  /// **'Ver comparación'**
  String get photoCompareView;

  /// No description provided for @photoError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar la foto.'**
  String get photoError;

  /// No description provided for @photoMissing.
  ///
  /// In es, this message translates to:
  /// **'Alguna de las fotos ya no está disponible.'**
  String get photoMissing;

  /// No description provided for @comparisonTitle.
  ///
  /// In es, this message translates to:
  /// **'Comparación'**
  String get comparisonTitle;

  /// No description provided for @mealsSoon.
  ///
  /// In es, this message translates to:
  /// **'Registra tus comidas del día.'**
  String get mealsSoon;

  /// No description provided for @settingsSoon.
  ///
  /// In es, this message translates to:
  /// **'Aquí configurarás tus metas, recordatorios y la clave de API.'**
  String get settingsSoon;

  /// No description provided for @muscleChest.
  ///
  /// In es, this message translates to:
  /// **'Pecho'**
  String get muscleChest;

  /// No description provided for @muscleBack.
  ///
  /// In es, this message translates to:
  /// **'Espalda'**
  String get muscleBack;

  /// No description provided for @muscleShoulders.
  ///
  /// In es, this message translates to:
  /// **'Hombros'**
  String get muscleShoulders;

  /// No description provided for @muscleBiceps.
  ///
  /// In es, this message translates to:
  /// **'Bíceps'**
  String get muscleBiceps;

  /// No description provided for @muscleTriceps.
  ///
  /// In es, this message translates to:
  /// **'Tríceps'**
  String get muscleTriceps;

  /// No description provided for @muscleLegs.
  ///
  /// In es, this message translates to:
  /// **'Piernas'**
  String get muscleLegs;

  /// No description provided for @muscleGlutes.
  ///
  /// In es, this message translates to:
  /// **'Glúteos'**
  String get muscleGlutes;

  /// No description provided for @muscleCore.
  ///
  /// In es, this message translates to:
  /// **'Core'**
  String get muscleCore;

  /// No description provided for @muscleCardio.
  ///
  /// In es, this message translates to:
  /// **'Cardio'**
  String get muscleCardio;

  /// No description provided for @muscleFullBody.
  ///
  /// In es, this message translates to:
  /// **'Cuerpo completo'**
  String get muscleFullBody;

  /// No description provided for @equipBarbell.
  ///
  /// In es, this message translates to:
  /// **'Barra'**
  String get equipBarbell;

  /// No description provided for @equipDumbbell.
  ///
  /// In es, this message translates to:
  /// **'Mancuernas'**
  String get equipDumbbell;

  /// No description provided for @equipMachine.
  ///
  /// In es, this message translates to:
  /// **'Máquina'**
  String get equipMachine;

  /// No description provided for @equipCable.
  ///
  /// In es, this message translates to:
  /// **'Polea'**
  String get equipCable;

  /// No description provided for @equipBodyweight.
  ///
  /// In es, this message translates to:
  /// **'Peso corporal'**
  String get equipBodyweight;

  /// No description provided for @equipOther.
  ///
  /// In es, this message translates to:
  /// **'Otro'**
  String get equipOther;

  /// No description provided for @exercisesTitle.
  ///
  /// In es, this message translates to:
  /// **'Ejercicios'**
  String get exercisesTitle;

  /// No description provided for @exercisesPickTitle.
  ///
  /// In es, this message translates to:
  /// **'Elegir ejercicios'**
  String get exercisesPickTitle;

  /// No description provided for @exercisesSearch.
  ///
  /// In es, this message translates to:
  /// **'Buscar ejercicio'**
  String get exercisesSearch;

  /// No description provided for @exercisesAll.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get exercisesAll;

  /// No description provided for @exercisesEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay ejercicios que coincidan con tu búsqueda.'**
  String get exercisesEmpty;

  /// No description provided for @exerciseNew.
  ///
  /// In es, this message translates to:
  /// **'Nuevo ejercicio'**
  String get exerciseNew;

  /// No description provided for @exerciseName.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get exerciseName;

  /// No description provided for @exerciseMuscle.
  ///
  /// In es, this message translates to:
  /// **'Grupo muscular'**
  String get exerciseMuscle;

  /// No description provided for @exerciseEquipment.
  ///
  /// In es, this message translates to:
  /// **'Equipo'**
  String get exerciseEquipment;

  /// No description provided for @exerciseCustom.
  ///
  /// In es, this message translates to:
  /// **'Propio'**
  String get exerciseCustom;

  /// No description provided for @exerciseInUse.
  ///
  /// In es, this message translates to:
  /// **'No se puede borrar: el ejercicio se usa en una rutina o en tu historial.'**
  String get exerciseInUse;

  /// No description provided for @exercisesAddSelected.
  ///
  /// In es, this message translates to:
  /// **'Añadir ({count})'**
  String exercisesAddSelected(int count);

  /// No description provided for @routinesEmpty.
  ///
  /// In es, this message translates to:
  /// **'Crea tu primera rutina para empezar a entrenar.'**
  String get routinesEmpty;

  /// No description provided for @routineNew.
  ///
  /// In es, this message translates to:
  /// **'Nueva rutina'**
  String get routineNew;

  /// No description provided for @routineEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar rutina'**
  String get routineEdit;

  /// No description provided for @routineName.
  ///
  /// In es, this message translates to:
  /// **'Nombre de la rutina'**
  String get routineName;

  /// No description provided for @routineNameRequired.
  ///
  /// In es, this message translates to:
  /// **'Ponle un nombre a la rutina'**
  String get routineNameRequired;

  /// No description provided for @routineAddExercises.
  ///
  /// In es, this message translates to:
  /// **'Añadir ejercicios'**
  String get routineAddExercises;

  /// No description provided for @routineNoExercises.
  ///
  /// In es, this message translates to:
  /// **'Añade al menos un ejercicio.'**
  String get routineNoExercises;

  /// No description provided for @routineExerciseCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =0{Sin ejercicios} =1{1 ejercicio} other{{count} ejercicios}}'**
  String routineExerciseCount(int count);

  /// No description provided for @routineDeleteTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Borrar rutina?'**
  String get routineDeleteTitle;

  /// No description provided for @routineDeleteBody.
  ///
  /// In es, this message translates to:
  /// **'Tu historial de entrenamientos se conserva.'**
  String get routineDeleteBody;

  /// No description provided for @ok.
  ///
  /// In es, this message translates to:
  /// **'Aceptar'**
  String get ok;

  /// No description provided for @historyTitle.
  ///
  /// In es, this message translates to:
  /// **'Historial'**
  String get historyTitle;

  /// No description provided for @historyEmpty.
  ///
  /// In es, this message translates to:
  /// **'Cuando termines tu primer entrenamiento aparecerá aquí.'**
  String get historyEmpty;

  /// No description provided for @workoutStart.
  ///
  /// In es, this message translates to:
  /// **'Entrenar'**
  String get workoutStart;

  /// No description provided for @workoutTitle.
  ///
  /// In es, this message translates to:
  /// **'Entrenamiento'**
  String get workoutTitle;

  /// No description provided for @workoutFinish.
  ///
  /// In es, this message translates to:
  /// **'Terminar'**
  String get workoutFinish;

  /// No description provided for @workoutDiscard.
  ///
  /// In es, this message translates to:
  /// **'Descartar entrenamiento'**
  String get workoutDiscard;

  /// No description provided for @workoutDiscardTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Descartar entrenamiento?'**
  String get workoutDiscardTitle;

  /// No description provided for @workoutDiscardBody.
  ///
  /// In es, this message translates to:
  /// **'Se perderán las series registradas.'**
  String get workoutDiscardBody;

  /// No description provided for @workoutFinishTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Terminar entrenamiento?'**
  String get workoutFinishTitle;

  /// No description provided for @workoutFinishBody.
  ///
  /// In es, this message translates to:
  /// **'Las series sin completar se descartarán.'**
  String get workoutFinishBody;

  /// No description provided for @workoutNothingDone.
  ///
  /// In es, this message translates to:
  /// **'Marca al menos una serie como completada.'**
  String get workoutNothingDone;

  /// No description provided for @workoutNotFound.
  ///
  /// In es, this message translates to:
  /// **'No se encontró el entrenamiento.'**
  String get workoutNotFound;

  /// No description provided for @workoutInProgress.
  ///
  /// In es, this message translates to:
  /// **'Entrenamiento en curso'**
  String get workoutInProgress;

  /// No description provided for @workoutContinue.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get workoutContinue;

  /// No description provided for @setWeight.
  ///
  /// In es, this message translates to:
  /// **'Peso (kg)'**
  String get setWeight;

  /// No description provided for @setDone.
  ///
  /// In es, this message translates to:
  /// **'Serie completada'**
  String get setDone;

  /// No description provided for @addSet.
  ///
  /// In es, this message translates to:
  /// **'Añadir serie'**
  String get addSet;

  /// No description provided for @lastTime.
  ///
  /// In es, this message translates to:
  /// **'Última vez: {sets}'**
  String lastTime(String sets);

  /// No description provided for @lastTimeNone.
  ///
  /// In es, this message translates to:
  /// **'Primera vez con este ejercicio'**
  String get lastTimeNone;

  /// No description provided for @restTimer.
  ///
  /// In es, this message translates to:
  /// **'Descanso'**
  String get restTimer;

  /// No description provided for @restSkip.
  ///
  /// In es, this message translates to:
  /// **'Saltar'**
  String get restSkip;

  /// No description provided for @restDuration.
  ///
  /// In es, this message translates to:
  /// **'Descanso: {seconds} s'**
  String restDuration(int seconds);

  /// No description provided for @newRecordsTitle.
  ///
  /// In es, this message translates to:
  /// **'¡Nuevo récord!'**
  String get newRecordsTitle;

  /// No description provided for @newRecordsBody.
  ///
  /// In es, this message translates to:
  /// **'Superaste tu marca en: {names}'**
  String newRecordsBody(String names);

  /// No description provided for @recordsTitle.
  ///
  /// In es, this message translates to:
  /// **'Récords personales'**
  String get recordsTitle;

  /// No description provided for @recordsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Tus récords aparecerán cuando completes series.'**
  String get recordsEmpty;

  /// No description provided for @recordMaxWeight.
  ///
  /// In es, this message translates to:
  /// **'Peso máx.'**
  String get recordMaxWeight;

  /// No description provided for @record1RM.
  ///
  /// In es, this message translates to:
  /// **'1RM est.'**
  String get record1RM;

  /// No description provided for @recordMaxReps.
  ///
  /// In es, this message translates to:
  /// **'Máx. repeticiones: {reps}'**
  String recordMaxReps(int reps);

  /// No description provided for @durationMin.
  ///
  /// In es, this message translates to:
  /// **'{minutes} min'**
  String durationMin(int minutes);

  /// No description provided for @workoutSummary.
  ///
  /// In es, this message translates to:
  /// **'{sets} series · {volume} kg'**
  String workoutSummary(int sets, String volume);

  /// No description provided for @sets.
  ///
  /// In es, this message translates to:
  /// **'Series'**
  String get sets;

  /// No description provided for @reps.
  ///
  /// In es, this message translates to:
  /// **'Reps'**
  String get reps;

  /// No description provided for @routineSetsReps.
  ///
  /// In es, this message translates to:
  /// **'{sets} × {reps}'**
  String routineSetsReps(int sets, int reps);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
