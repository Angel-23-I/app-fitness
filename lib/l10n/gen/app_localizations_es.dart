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
  String get todaySuggested => 'Entrenamiento sugerido para hoy';

  @override
  String get streakDays => 'días seguidos';

  @override
  String get streakWeeks => 'semanas cumpliendo tu meta';

  @override
  String get weekProgress => 'Progreso semanal';

  @override
  String weekProgressCount(int done, int goal) {
    return '$done de $goal entrenamientos';
  }

  @override
  String get currentWeight => 'Peso actual';

  @override
  String weightToGoal(String diff, String target) {
    return 'A $diff kg de tu meta ($target kg)';
  }

  @override
  String get goalsTitle => 'Metas';

  @override
  String get goalsSubtitle =>
      'Peso objetivo, entrenamientos por semana y calorías';

  @override
  String get goalTargetWeight => 'Peso objetivo (opcional)';

  @override
  String get goalWeeklyWorkouts => 'Entrenamientos por semana (1 a 7)';

  @override
  String get goalDailyCalories => 'Meta de calorías diarias (opcional)';

  @override
  String get goalsInvalid =>
      'Revisa los valores: peso 20–400 kg, 1–7 entrenamientos y calorías 500–10000.';

  @override
  String get remindersTitle => 'Recordatorios';

  @override
  String get remindersSubtitle => 'Avisos para entrenar en tus días y hora';

  @override
  String get remindersEmpty =>
      'Programa un aviso para no saltarte el entrenamiento.';

  @override
  String get reminderAdd => 'Nuevo recordatorio';

  @override
  String get reminderDays => 'Días de la semana';

  @override
  String get reminderPermissionDenied =>
      'Sin permiso de notificaciones. Actívalo en los ajustes del sistema.';

  @override
  String get reminderNotificationTitle => '¡Hora de entrenar! 💪';

  @override
  String get reminderNotificationBody => 'Tu rutina de hoy te está esperando.';

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
  String get today => 'Hoy';

  @override
  String get caloriesToday => 'Calorías de hoy';

  @override
  String get mealsEmpty => 'Aún no has registrado comidas este día.';

  @override
  String get mealAdd => 'Añadir comida';

  @override
  String get mealFromCamera => 'Foto con la cámara';

  @override
  String get mealFromGallery => 'Foto de la galería';

  @override
  String get aiNeedsKey =>
      'Configura tu clave de API en Ajustes para activarlo.';

  @override
  String get addManually => 'Añadir manualmente';

  @override
  String get aiDisabledTitle => 'Análisis por foto desactivado';

  @override
  String get aiDisabledBody =>
      'Añade tu clave de API de Gemini para calcular calorías desde una foto. Mientras tanto puedes registrar comidas a mano.';

  @override
  String get configureKey => 'Configurar';

  @override
  String get mealBreakfast => 'Desayuno';

  @override
  String get mealLunch => 'Almuerzo';

  @override
  String get mealDinner => 'Cena';

  @override
  String get mealSnack => 'Snack';

  @override
  String get mealType => 'Tipo de comida';

  @override
  String get mealReviewTitle => 'Revisa tu comida';

  @override
  String get analyzing => 'Analizando tu foto…';

  @override
  String get estimateDisclaimer =>
      'Estimación aproximada hecha por IA: puede equivocarse en alimentos y porciones. Revisa y corrige antes de guardar.';

  @override
  String confidenceLabel(String level) {
    return 'Confianza: $level';
  }

  @override
  String get confidenceHigh => 'alta';

  @override
  String get confidenceMedium => 'media';

  @override
  String get confidenceLow => 'baja';

  @override
  String get foodName => 'Alimento';

  @override
  String get grams => 'Porción';

  @override
  String get protein => 'Prot.';

  @override
  String get carbs => 'Carb.';

  @override
  String get fat => 'Grasa';

  @override
  String get addFoodItem => 'Añadir alimento';

  @override
  String get mealTotal => 'Total de la comida';

  @override
  String macrosLine(String p, String c, String f) {
    return 'Proteínas $p g · Carbohidratos $c g · Grasas $f g';
  }

  @override
  String get mealNeedItem => 'Añade al menos un alimento con nombre.';

  @override
  String get mealSave => 'Guardar comida';

  @override
  String get errNoApiKey => 'Aún no has configurado tu clave de API de Gemini.';

  @override
  String get errNoInternet =>
      'No hay conexión a internet. Revisa tu red e inténtalo de nuevo.';

  @override
  String get errInvalidKey =>
      'La clave de API no es válida o no tiene permisos. Revísala en Ajustes.';

  @override
  String get errQuota =>
      'Se alcanzó el límite de uso de la API. Espera un rato o revisa tu cuota.';

  @override
  String get errUnparseable =>
      'No se pudo entender la respuesta de la IA. Inténtalo de nuevo o añade la comida a mano.';

  @override
  String get errNoFood =>
      'No se detectó comida en la foto. Prueba con otra imagen más clara.';

  @override
  String get errServer =>
      'El servicio de IA no está disponible ahora mismo. Inténtalo más tarde.';

  @override
  String get apiKeyTitle => 'Análisis de comida con IA';

  @override
  String get apiKeySubtitle => 'Clave de API de Gemini';

  @override
  String get apiKeyIntro =>
      'La app puede estimar calorías y macros a partir de una foto usando la API de Gemini de Google. Necesitas tu propia clave, que se guarda cifrada solo en este dispositivo.';

  @override
  String get apiKeyStepsTitle => 'Cómo obtenerla';

  @override
  String get apiKeySteps =>
      '1. Entra con tu cuenta de Google en Google AI Studio.\n2. Crea una clave de API.\n3. Cópiala y pégala aquí.';

  @override
  String get apiKeyPrivacy =>
      'Al analizar una comida, la foto reducida se envía a Google. Las estimaciones son aproximadas y no sustituyen el consejo de un profesional de la nutrición. Tu clave nunca sale del dispositivo salvo para llamar a la API.';

  @override
  String get apiKeyField => 'Clave de API';

  @override
  String get apiKeySaved => 'Clave guardada';

  @override
  String get apiKeyRemove => 'Quitar';

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

  @override
  String get homeHeadlineLead => 'Vamos a';

  @override
  String get homeHeadlineAccent => 'entrenar';

  @override
  String get ringWorkouts => 'Entrenos';

  @override
  String get ringCalories => 'Calorías';

  @override
  String get ringStreak => 'Racha';

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '1 día',
    );
    return '$_temp0';
  }

  @override
  String weeksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count semanas',
      one: '1 semana',
    );
    return '$_temp0';
  }

  @override
  String ringsSemantics(int done, int goal, int streak) {
    return 'Esta semana: $done de $goal entrenamientos. Racha de $streak días.';
  }

  @override
  String get weekGoalStreak => 'Semanas cumpliendo tu meta';

  @override
  String get kcalLeft => 'kcal restantes';

  @override
  String get kcalOver => 'kcal de más';

  @override
  String get kcalEaten => 'kcal hoy';

  @override
  String get macroProtein => 'Proteína';

  @override
  String get macroCarbs => 'Carbohidratos';

  @override
  String get macroFat => 'Grasas';

  @override
  String get scanMealTitle => 'Escanear comida con IA';

  @override
  String get scanMealSubtitle => 'Haz una foto y revisa la estimación';

  @override
  String exerciseOf(int index, int total) {
    return 'Ejercicio $index de $total';
  }

  @override
  String get setLabel => 'Serie';

  @override
  String get myRoutines => 'Mis rutinas';

  @override
  String get workoutDoneTitle => '¡Entrenamiento completado!';

  @override
  String workoutDoneSubtitle(String name) {
    return '$name · buen trabajo hoy';
  }

  @override
  String get statDuration => 'Duración';

  @override
  String get statVolume => 'Peso levantado';

  @override
  String get statSets => 'Series';

  @override
  String get statExercises => 'Ejercicios';

  @override
  String get streakTitle => 'Tu racha';

  @override
  String streakKeepGoing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '¡$count días seguidos entrenando! No la rompas.',
      one: '¡Primer día! Vuelve mañana para seguir sumando.',
    );
    return '$_temp0';
  }

  @override
  String get weekThisWeek => 'Esta semana';

  @override
  String get viewDetail => 'Ver detalle';

  @override
  String get backHome => 'Volver al inicio';
}
