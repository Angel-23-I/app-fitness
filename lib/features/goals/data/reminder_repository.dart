import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/providers.dart';
import 'notification_scheduler.dart';

/// Keeps the reminders table and the OS-scheduled notifications in step.
class ReminderRepository {
  ReminderRepository(this._db, this._scheduler);
  final AppDatabase _db;
  final NotificationScheduler _scheduler;

  Stream<List<Reminder>> watchAll() => (_db.select(_db.reminders)
        ..orderBy([(t) => OrderingTerm.asc(t.weekday), (t) => OrderingTerm.asc(t.hour), (t) => OrderingTerm.asc(t.minute)]))
      .watch();

  /// Creates one reminder per weekday at the given time. Returns false (and saves nothing)
  /// when the user denies the notification permission.
  Future<bool> add(Set<int> weekdays, int hour, int minute) async {
    if (!await _scheduler.requestPermission()) return false;
    for (final day in weekdays) {
      final id = await _db.into(_db.reminders).insert(
          RemindersCompanion.insert(weekday: day, hour: hour, minute: minute));
      await _scheduler.scheduleWeekly(id: id, weekday: day, hour: hour, minute: minute);
    }
    return true;
  }

  Future<void> setEnabled(Reminder r, bool enabled) async {
    await (_db.update(_db.reminders)..where((t) => t.id.equals(r.id)))
        .write(RemindersCompanion(enabled: Value(enabled)));
    if (enabled) {
      await _scheduler.scheduleWeekly(id: r.id, weekday: r.weekday, hour: r.hour, minute: r.minute);
    } else {
      await _scheduler.cancel(r.id);
    }
  }

  Future<void> delete(Reminder r) async {
    await _scheduler.cancel(r.id);
    await (_db.delete(_db.reminders)..where((t) => t.id.equals(r.id))).go();
  }

  /// Re-registers every enabled reminder (e.g. at app start); scheduling is idempotent per id.
  Future<void> syncAll() async {
    final all = await (_db.select(_db.reminders)..where((t) => t.enabled.equals(true))).get();
    for (final r in all) {
      await _scheduler.scheduleWeekly(id: r.id, weekday: r.weekday, hour: r.hour, minute: r.minute);
    }
  }
}

final reminderRepositoryProvider = Provider((ref) =>
    ReminderRepository(ref.watch(databaseProvider), ref.watch(notificationSchedulerProvider)));

final remindersProvider = StreamProvider.autoDispose<List<Reminder>>(
    (ref) => ref.watch(reminderRepositoryProvider).watchAll());
