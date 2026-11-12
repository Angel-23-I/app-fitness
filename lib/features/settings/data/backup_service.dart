import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/enums.dart';
import '../../../core/db/providers.dart';

class BackupService {
  BackupService(this._db);
  final AppDatabase _db;

  Future<Directory> _getBackupDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'fittrack_backups'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<Directory> _getExportDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'fittrack_exports'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Genera un JSON con todos los datos del usuario.
  Future<String> exportBackupJson() async {
    final settings = await _db.select(_db.appSettings).get();
    final customExercises = await (_db.select(_db.exercises)
          ..where((t) => t.isCustom.equals(true)))
        .get();
    final routines = await _db.select(_db.routines).get();
    final routineExercises = await _db.select(_db.routineExercises).get();
    final workouts = await _db.select(_db.workouts).get();
    final workoutSets = await _db.select(_db.workoutSets).get();
    final bodyEntries = await _db.select(_db.bodyEntries).get();
    final meals = await _db.select(_db.meals).get();
    final mealItems = await _db.select(_db.mealItems).get();
    final reminders = await _db.select(_db.reminders).get();

    final data = <String, dynamic>{
      'version': 1,
      'appName': 'FitTrack',
      'exportedAt': DateTime.now().toIso8601String(),
      'settings': [
        for (final s in settings) {'key': s.key, 'value': s.value}
      ],
      'customExercises': [
        for (final e in customExercises)
          {
            'name': e.name,
            'muscleGroup': e.muscleGroup.name,
            'equipment': e.equipment.name,
          }
      ],
      'routines': [
        for (final r in routines)
          {
            'id': r.id,
            'name': r.name,
            'createdAt': r.createdAt.toIso8601String(),
          }
      ],
      'routineExercises': [
        for (final re in routineExercises)
          {
            'routineId': re.routineId,
            'exerciseId': re.exerciseId,
            'position': re.position,
            'targetSets': re.targetSets,
            'targetReps': re.targetReps,
          }
      ],
      'workouts': [
        for (final w in workouts)
          {
            'id': w.id,
            'routineId': w.routineId,
            'name': w.name,
            'startedAt': w.startedAt.toIso8601String(),
            'endedAt': w.endedAt?.toIso8601String(),
          }
      ],
      'workoutSets': [
        for (final s in workoutSets)
          {
            'workoutId': s.workoutId,
            'exerciseId': s.exerciseId,
            'exerciseOrder': s.exerciseOrder,
            'setNumber': s.setNumber,
            'reps': s.reps,
            'weightKg': s.weightKg,
            'completed': s.completed,
          }
      ],
      'bodyEntries': [
        for (final b in bodyEntries)
          {
            'date': b.date.toIso8601String(),
            'weightKg': b.weightKg,
            'waistCm': b.waistCm,
            'chestCm': b.chestCm,
            'armCm': b.armCm,
            'thighCm': b.thighCm,
          }
      ],
      'meals': [
        for (final m in meals)
          {
            'id': m.id,
            'eatenAt': m.eatenAt.toIso8601String(),
            'mealType': m.mealType.name,
          }
      ],
      'mealItems': [
        for (final mi in mealItems)
          {
            'mealId': mi.mealId,
            'name': mi.name,
            'grams': mi.grams,
            'kcal': mi.kcal,
            'proteinG': mi.proteinG,
            'carbsG': mi.carbsG,
            'fatG': mi.fatG,
          }
      ],
      'reminders': [
        for (final rem in reminders)
          {
            'weekday': rem.weekday,
            'hour': rem.hour,
            'minute': rem.minute,
            'enabled': rem.enabled,
          }
      ],
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Guarda una copia JSON en el almacenamiento local de la app.
  Future<File> saveBackupToFile([String? jsonString]) async {
    final content = jsonString ?? await exportBackupJson();
    final dir = await _getBackupDir();
    final now = DateTime.now();
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    final file = File(p.join(dir.path, 'fittrack_backup_$dateStr.json'));
    return file.writeAsString(content);
  }

  /// Lista los backups guardados en el dispositivo.
  Future<List<File>> listBackups() async {
    final dir = await _getBackupDir();
    final entities = await dir.list().toList();
    final files = entities.whereType<File>().where((f) => f.path.endsWith('.json')).toList();
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    return files;
  }

  /// Elimina un archivo de backup.
  Future<void> deleteBackupFile(File file) async {
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Restaura datos a partir de una cadena JSON.
  Future<Map<String, int>> restoreBackupFromJson(String jsonStr) async {
    final Map<String, dynamic> data = jsonDecode(jsonStr) as Map<String, dynamic>;
    if (data['appName'] != 'FitTrack' && !data.containsKey('workouts')) {
      throw const FormatException('El formato del archivo no corresponde a una copia válida de FitTrack');
    }

    final counts = <String, int>{
      'workouts': 0,
      'routines': 0,
      'bodyEntries': 0,
      'meals': 0,
    };

    await _db.transaction(() async {
      // 1. Restaurar Ajustes
      if (data['settings'] case final List list) {
        for (final item in list) {
          if (item is Map) {
            final k = item['key']?.toString();
            final v = item['value']?.toString();
            if (k != null && v != null) {
              await _db.into(_db.appSettings).insertOnConflictUpdate(
                    AppSettingsCompanion.insert(key: k, value: v),
                  );
            }
          }
        }
      }

      // 2. Ejercicios personalizados
      final existingExercises = await _db.select(_db.exercises).get();
      final exerciseMap = {for (final e in existingExercises) e.name.toLowerCase(): e.id};

      if (data['customExercises'] case final List list) {
        for (final item in list) {
          if (item is Map) {
            final name = item['name']?.toString() ?? '';
            if (name.isNotEmpty && !exerciseMap.containsKey(name.toLowerCase())) {
              final mg = MuscleGroup.values.firstWhere(
                (m) => m.name == item['muscleGroup'],
                orElse: () => MuscleGroup.chest,
              );
              final eq = Equipment.values.firstWhere(
                (e) => e.name == item['equipment'],
                orElse: () => Equipment.barbell,
              );
              final newId = await _db.into(_db.exercises).insert(
                    ExercisesCompanion.insert(
                      name: name,
                      muscleGroup: mg,
                      equipment: eq,
                      isCustom: const Value(true),
                    ),
                  );
              exerciseMap[name.toLowerCase()] = newId;
            }
          }
        }
      }

      // Re-consultar todos los ejercicios para mapear IDs
      final allExercises = await _db.select(_db.exercises).get();
      final idToExercise = {for (final e in allExercises) e.id: e};

      // 3. Rutinas
      final routineIdMap = <int, int>{};
      if (data['routines'] case final List list) {
        for (final item in list) {
          if (item is Map) {
            final oldId = item['id'] as int?;
            final name = item['name']?.toString() ?? 'Rutina';
            final createdAt = DateTime.tryParse(item['createdAt']?.toString() ?? '') ?? DateTime.now();

            final newId = await _db.into(_db.routines).insert(
                  RoutinesCompanion.insert(
                    name: name,
                    createdAt: Value(createdAt),
                  ),
                );
            if (oldId != null) routineIdMap[oldId] = newId;
            counts['routines'] = (counts['routines'] ?? 0) + 1;
          }
        }
      }

      // 3b. Ejercicios de rutinas
      if (data['routineExercises'] case final List list) {
        for (final item in list) {
          if (item is Map) {
            final oldRoutineId = item['routineId'] as int?;
            final newRoutineId = oldRoutineId != null ? routineIdMap[oldRoutineId] : null;
            final exId = item['exerciseId'] as int?;

            if (newRoutineId != null && exId != null && idToExercise.containsKey(exId)) {
              await _db.into(_db.routineExercises).insert(
                    RoutineExercisesCompanion.insert(
                      routineId: newRoutineId,
                      exerciseId: exId,
                      position: (item['position'] as int?) ?? 0,
                      targetSets: Value((item['targetSets'] as int?) ?? 3),
                      targetReps: Value((item['targetReps'] as int?) ?? 10),
                    ),
                  );
            }
          }
        }
      }

      // 4. Entrenamientos y Series
      final workoutIdMap = <int, int>{};
      if (data['workouts'] case final List list) {
        for (final item in list) {
          if (item is Map) {
            final oldId = item['id'] as int?;
            final oldRoutineId = item['routineId'] as int?;
            final newRoutineId = oldRoutineId != null ? routineIdMap[oldRoutineId] : null;
            final name = item['name']?.toString() ?? 'Entrenamiento';
            final startedAt = DateTime.tryParse(item['startedAt']?.toString() ?? '') ?? DateTime.now();
            final endedAt = DateTime.tryParse(item['endedAt']?.toString() ?? '');

            final newId = await _db.into(_db.workouts).insert(
                  WorkoutsCompanion.insert(
                    routineId: Value(newRoutineId),
                    name: name,
                    startedAt: startedAt,
                    endedAt: Value(endedAt),
                  ),
                );
            if (oldId != null) workoutIdMap[oldId] = newId;
            counts['workouts'] = (counts['workouts'] ?? 0) + 1;
          }
        }
      }

      // 4b. Series de entrenamientos
      if (data['workoutSets'] case final List list) {
        for (final item in list) {
          if (item is Map) {
            final oldWorkoutId = item['workoutId'] as int?;
            final newWorkoutId = oldWorkoutId != null ? workoutIdMap[oldWorkoutId] : null;
            final exId = item['exerciseId'] as int?;

            if (newWorkoutId != null && exId != null && idToExercise.containsKey(exId)) {
              await _db.into(_db.workoutSets).insert(
                    WorkoutSetsCompanion.insert(
                      workoutId: newWorkoutId,
                      exerciseId: exId,
                      exerciseOrder: (item['exerciseOrder'] as int?) ?? 0,
                      setNumber: (item['setNumber'] as int?) ?? 1,
                      reps: Value((item['reps'] as int?) ?? 0),
                      weightKg: Value((item['weightKg'] as num?)?.toDouble() ?? 0.0),
                      completed: Value((item['completed'] as bool?) ?? false),
                    ),
                  );
            }
          }
        }
      }

      // 5. Medidas corporales
      if (data['bodyEntries'] case final List list) {
        for (final item in list) {
          if (item is Map) {
            final date = DateTime.tryParse(item['date']?.toString() ?? '') ?? DateTime.now();
            await _db.into(_db.bodyEntries).insert(
                  BodyEntriesCompanion.insert(
                    date: date,
                    weightKg: Value((item['weightKg'] as num?)?.toDouble()),
                    waistCm: Value((item['waistCm'] as num?)?.toDouble()),
                    chestCm: Value((item['chestCm'] as num?)?.toDouble()),
                    armCm: Value((item['armCm'] as num?)?.toDouble()),
                    thighCm: Value((item['thighCm'] as num?)?.toDouble()),
                  ),
                );
            counts['bodyEntries'] = (counts['bodyEntries'] ?? 0) + 1;
          }
        }
      }

      // 6. Comidas
      final mealIdMap = <int, int>{};
      if (data['meals'] case final List list) {
        for (final item in list) {
          if (item is Map) {
            final oldId = item['id'] as int?;
            final eatenAt = DateTime.tryParse(item['eatenAt']?.toString() ?? '') ?? DateTime.now();
            final mt = MealType.values.firstWhere(
              (m) => m.name == item['mealType'],
              orElse: () => MealType.snack,
            );

            final newId = await _db.into(_db.meals).insert(
                  MealsCompanion.insert(
                    eatenAt: eatenAt,
                    mealType: Value(mt),
                  ),
                );
            if (oldId != null) mealIdMap[oldId] = newId;
            counts['meals'] = (counts['meals'] ?? 0) + 1;
          }
        }
      }

      // 6b. Items de comida
      if (data['mealItems'] case final List list) {
        for (final item in list) {
          if (item is Map) {
            final oldMealId = item['mealId'] as int?;
            final newMealId = oldMealId != null ? mealIdMap[oldMealId] : null;

            if (newMealId != null) {
              await _db.into(_db.mealItems).insert(
                    MealItemsCompanion.insert(
                      mealId: newMealId,
                      name: item['name']?.toString() ?? '',
                      grams: (item['grams'] as num?)?.toDouble() ?? 100.0,
                      kcal: (item['kcal'] as num?)?.toDouble() ?? 0.0,
                      proteinG: (item['proteinG'] as num?)?.toDouble() ?? 0.0,
                      carbsG: (item['carbsG'] as num?)?.toDouble() ?? 0.0,
                      fatG: (item['fatG'] as num?)?.toDouble() ?? 0.0,
                    ),
                  );
            }
          }
        }
      }

      // 7. Recordatorios
      if (data['reminders'] case final List list) {
        for (final item in list) {
          if (item is Map) {
            final weekday = item['weekday'] as int?;
            final hour = item['hour'] as int?;
            final minute = item['minute'] as int?;
            if (weekday != null && hour != null && minute != null) {
              await _db.into(_db.reminders).insert(
                    RemindersCompanion.insert(
                      weekday: weekday,
                      hour: hour,
                      minute: minute,
                      enabled: Value((item['enabled'] as bool?) ?? true),
                    ),
                  );
            }
          }
        }
      }
    });

    return counts;
  }

  /// Exporta historial de entrenamientos a CSV.
  Future<String> exportWorkoutsCsv() async {
    final sets = _db.workoutSets;
    final workouts = _db.workouts;
    final exercises = _db.exercises;

    final rows = await (_db.select(sets).join([
      innerJoin(workouts, workouts.id.equalsExp(sets.workoutId)),
      innerJoin(exercises, exercises.id.equalsExp(sets.exerciseId)),
    ])
          ..where(sets.completed.equals(true) & workouts.endedAt.isNotNull())
          ..orderBy([
            OrderingTerm.desc(workouts.startedAt),
            OrderingTerm.asc(sets.exerciseOrder),
            OrderingTerm.asc(sets.setNumber),
          ]))
        .get();

    final buffer = StringBuffer();
    buffer.writeln('ID_Entrenamiento,Fecha,Nombre_Sesion,Ejercicio,Numero_Serie,Peso_Kg,Repeticiones,Completado');

    for (final r in rows) {
      final w = r.readTable(workouts);
      final s = r.readTable(sets);
      final e = r.readTable(exercises);

      final dateStr = w.startedAt.toIso8601String().split('T').first;
      final sessionName = '"${w.name.replaceAll('"', '""')}"';
      final exName = '"${e.name.replaceAll('"', '""')}"';

      buffer.writeln('${w.id},$dateStr,$sessionName,$exName,${s.setNumber},${s.weightKg},${s.reps},${s.completed}');
    }

    return buffer.toString();
  }

  /// Exporta medidas corporales a CSV.
  Future<String> exportMeasuresCsv() async {
    final entries = await (_db.select(_db.bodyEntries)
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();

    final buffer = StringBuffer();
    buffer.writeln('ID,Fecha,Peso_Kg,Cintura_Cm,Pecho_Cm,Brazo_Cm,Muslo_Cm');

    for (final b in entries) {
      final dateStr = b.date.toIso8601String().split('T').first;
      buffer.writeln('${b.id},$dateStr,${b.weightKg ?? ""},${b.waistCm ?? ""},${b.chestCm ?? ""},${b.armCm ?? ""},${b.thighCm ?? ""}');
    }

    return buffer.toString();
  }

  /// Guarda contenido CSV en archivo en la carpeta de exportaciones.
  Future<File> saveCsvToFile(String baseName, String content) async {
    final dir = await _getExportDir();
    final now = DateTime.now();
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final file = File(p.join(dir.path, '${baseName}_$dateStr.csv'));
    return file.writeAsString(content);
  }
}

final backupServiceProvider =
    Provider((ref) => BackupService(ref.watch(databaseProvider)));
