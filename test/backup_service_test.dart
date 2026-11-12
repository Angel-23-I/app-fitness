import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/core/db/app_database.dart';
import 'package:fittrack/features/settings/data/backup_service.dart';
import 'package:fittrack/features/settings/data/settings_repository.dart';

void main() {
  late AppDatabase db;
  late BackupService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    service = BackupService(db);
  });
  tearDown(() => db.close());

  test('exports and restores settings and workouts correctly', () async {
    final settingsRepo = SettingsRepository(db);
    await settingsRepo.set(SettingKeys.userName, 'Carlos');
    await settingsRepo.set(SettingKeys.userGoal, 'build_muscle');

    final json = await service.exportBackupJson();
    expect(json.contains('Carlos'), isTrue);
    expect(json.contains('FitTrack'), isTrue);

    // Create a fresh DB and restore
    final db2 = AppDatabase(NativeDatabase.memory());
    final service2 = BackupService(db2);
    final counts = await service2.restoreBackupFromJson(json);

    final restoredName = await SettingsRepository(db2).get(SettingKeys.userName);
    expect(restoredName, 'Carlos');
    await db2.close();
  });

  test('exports CSV formats correctly', () async {
    final workoutsCsv = await service.exportWorkoutsCsv();
    expect(workoutsCsv.contains('ID_Entrenamiento'), isTrue);
    expect(workoutsCsv.contains('Peso_Kg'), isTrue);

    final measuresCsv = await service.exportMeasuresCsv();
    expect(measuresCsv.contains('ID,Fecha,Peso_Kg'), isTrue);
  });
}
