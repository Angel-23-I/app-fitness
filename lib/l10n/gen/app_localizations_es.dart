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
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

  @override
  String get delete => 'Borrar';

  @override
  String get edit => 'Editar';

  @override
  String get homeSoon => 'Tu resumen del día aparecerá aquí.';

  @override
  String get tabMeasures => 'Medidas';

  @override
  String get tabPhotos => 'Fotos';

  @override
  String get range1m => '1 mes';

  @override
  String get range3m => '3 meses';

  @override
  String get rangeAll => 'Todo';

  @override
  String get metricWeight => 'Peso';

  @override
  String get metricWaist => 'Cintura';

  @override
  String get metricChest => 'Pecho';

  @override
  String get metricArm => 'Brazo';

  @override
  String get metricThigh => 'Muslo';

  @override
  String get entryAdd => 'Registrar';

  @override
  String get entryDate => 'Fecha';

  @override
  String get entryNeedValue => 'Introduce al menos un valor.';

  @override
  String get measuresEmpty =>
      'Registra tu peso y medidas para ver tu evolución.';

  @override
  String get chartNeedMore =>
      'Registra al menos dos mediciones para ver la gráfica.';

  @override
  String get photosEmpty => 'Añade tu primera foto de progreso.';

  @override
  String get photoAdd => 'Añadir foto';

  @override
  String get photoCamera => 'Tomar foto';

  @override
  String get photoGallery => 'Elegir de la galería';

  @override
  String get photoCompare => 'Comparar';

  @override
  String get photoCompareHint => 'Elige dos fotos';

  @override
  String get photoCompareView => 'Ver comparación';

  @override
  String get photoError => 'No se pudo guardar la foto.';

  @override
  String get photoMissing => 'Alguna de las fotos ya no está disponible.';

  @override
  String get comparisonTitle => 'Comparación';

  @override
  String get mealsSoon => 'Registra tus comidas del día.';

  @override
  String get settingsSoon =>
      'Aquí configurarás tus metas, recordatorios y la clave de API.';

  @override
  String get muscleChest => 'Pecho';

  @override
  String get muscleBack => 'Espalda';

  @override
  String get muscleShoulders => 'Hombros';

  @override
  String get muscleBiceps => 'Bíceps';

  @override
  String get muscleTriceps => 'Tríceps';

  @override
  String get muscleLegs => 'Piernas';

  @override
  String get muscleGlutes => 'Glúteos';

  @override
  String get muscleCore => 'Core';

  @override
  String get muscleCardio => 'Cardio';

  @override
  String get muscleFullBody => 'Cuerpo completo';

  @override
  String get equipBarbell => 'Barra';

  @override
  String get equipDumbbell => 'Mancuernas';

  @override
  String get equipMachine => 'Máquina';

  @override
  String get equipCable => 'Polea';

  @override
  String get equipBodyweight => 'Peso corporal';

  @override
  String get equipOther => 'Otro';

  @override
  String get exercisesTitle => 'Ejercicios';

  @override
  String get exercisesPickTitle => 'Elegir ejercicios';

  @override
  String get exercisesSearch => 'Buscar ejercicio';

  @override
  String get exercisesAll => 'Todos';

  @override
  String get exercisesEmpty =>
      'No hay ejercicios que coincidan con tu búsqueda.';

  @override
  String get exerciseNew => 'Nuevo ejercicio';

  @override
  String get exerciseName => 'Nombre';

  @override
  String get exerciseMuscle => 'Grupo muscular';

  @override
  String get exerciseEquipment => 'Equipo';

  @override
  String get exerciseCustom => 'Propio';

  @override
  String get exerciseInUse =>
      'No se puede borrar: el ejercicio se usa en una rutina o en tu historial.';

  @override
  String exercisesAddSelected(int count) {
    return 'Añadir ($count)';
  }

  @override
  String get routinesEmpty => 'Crea tu primera rutina para empezar a entrenar.';

  @override
  String get routineNew => 'Nueva rutina';

  @override
  String get routineEdit => 'Editar rutina';

  @override
  String get routineName => 'Nombre de la rutina';

  @override
  String get routineNameRequired => 'Ponle un nombre a la rutina';

  @override
  String get routineAddExercises => 'Añadir ejercicios';

  @override
  String get routineNoExercises => 'Añade al menos un ejercicio.';

  @override
  String routineExerciseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ejercicios',
      one: '1 ejercicio',
      zero: 'Sin ejercicios',
    );
    return '$_temp0';
  }

  @override
  String get routineDeleteTitle => '¿Borrar rutina?';

  @override
  String get routineDeleteBody => 'Tu historial de entrenamientos se conserva.';

  @override
  String get ok => 'Aceptar';

  @override
  String get historyTitle => 'Historial';

  @override
  String get historyEmpty =>
      'Cuando termines tu primer entrenamiento aparecerá aquí.';

  @override
  String get workoutStart => 'Entrenar';

  @override
  String get workoutTitle => 'Entrenamiento';

  @override
  String get workoutFinish => 'Terminar';

  @override
  String get workoutDiscard => 'Descartar entrenamiento';

  @override
  String get workoutDiscardTitle => '¿Descartar entrenamiento?';

  @override
  String get workoutDiscardBody => 'Se perderán las series registradas.';

  @override
  String get workoutFinishTitle => '¿Terminar entrenamiento?';

  @override
  String get workoutFinishBody => 'Las series sin completar se descartarán.';

  @override
  String get workoutNothingDone => 'Marca al menos una serie como completada.';

  @override
  String get workoutNotFound => 'No se encontró el entrenamiento.';

  @override
  String get workoutInProgress => 'Entrenamiento en curso';

  @override
  String get workoutContinue => 'Continuar';

  @override
  String get setWeight => 'Peso (kg)';

  @override
  String get setDone => 'Serie completada';

  @override
  String get addSet => 'Añadir serie';

  @override
  String lastTime(String sets) {
    return 'Última vez: $sets';
  }

  @override
  String get lastTimeNone => 'Primera vez con este ejercicio';

  @override
  String get restTimer => 'Descanso';

  @override
  String get restSkip => 'Saltar';

  @override
  String restDuration(int seconds) {
    return 'Descanso: $seconds s';
  }

  @override
  String get newRecordsTitle => '¡Nuevo récord!';

  @override
  String newRecordsBody(String names) {
    return 'Superaste tu marca en: $names';
  }

  @override
  String get recordsTitle => 'Récords personales';

  @override
  String get recordsEmpty => 'Tus récords aparecerán cuando completes series.';

  @override
  String get recordMaxWeight => 'Peso máx.';

  @override
  String get record1RM => '1RM est.';

  @override
  String recordMaxReps(int reps) {
    return 'Máx. repeticiones: $reps';
  }

  @override
  String durationMin(int minutes) {
    return '$minutes min';
  }

  @override
  String workoutSummary(int sets, String volume) {
    return '$sets series · $volume kg';
  }

  @override
  String get sets => 'Series';

  @override
  String get reps => 'Reps';

  @override
  String routineSetsReps(int sets, int reps) {
    return '$sets × $reps';
  }
}
