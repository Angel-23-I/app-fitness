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
  String get progressSoon =>
      'Registra tu peso y medidas para ver tu evolución.';

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
  String get historyTitle => 'Historial';

  @override
  String get workoutStart => 'Entrenar';

  @override
  String get sets => 'Series';

  @override
  String get reps => 'Reps';

  @override
  String routineSetsReps(int sets, int reps) {
    return '$sets × $reps';
  }
}
