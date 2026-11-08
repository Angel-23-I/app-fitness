import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/providers.dart';

/// Non-secret preferences and goals (key/value). Secrets go in secure storage instead.
class SettingsRepository {
  SettingsRepository(this._db);
  final AppDatabase _db;

  Stream<String?> watch(String key) => (_db.select(_db.appSettings)
        ..where((t) => t.key.equals(key)))
      .watchSingleOrNull()
      .map((r) => r?.value);

  Stream<Map<String, String>> watchAll() => _db
      .select(_db.appSettings)
      .watch()
      .map((rows) => {for (final r in rows) r.key: r.value});

  Future<String?> get(String key) async => (await (_db.select(_db.appSettings)
            ..where((t) => t.key.equals(key)))
          .getSingleOrNull())
      ?.value;

  /// A null [value] removes the key.
  Future<void> set(String key, String? value) async {
    if (value == null) {
      await (_db.delete(_db.appSettings)..where((t) => t.key.equals(key))).go();
    } else {
      await _db
          .into(_db.appSettings)
          .insertOnConflictUpdate(AppSettingsCompanion.insert(key: key, value: value));
    }
  }
}

final settingsRepositoryProvider =
    Provider((ref) => SettingsRepository(ref.watch(databaseProvider)));

class SettingKeys {
  static const restSeconds = 'restSeconds';
  static const targetWeight = 'targetWeight';
  static const weeklyWorkouts = 'weeklyWorkouts';
  static const dailyCalories = 'dailyCalories';
}

const defaultRestSeconds = 90;

final restSecondsProvider = StreamProvider<int>((ref) => ref
    .watch(settingsRepositoryProvider)
    .watch(SettingKeys.restSeconds)
    .map((v) => int.tryParse(v ?? '') ?? defaultRestSeconds));
