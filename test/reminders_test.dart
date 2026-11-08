import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fittrack/core/db/app_database.dart';
import 'package:fittrack/features/dashboard/domain/suggestion.dart';
import 'package:fittrack/features/goals/data/notification_scheduler.dart';
import 'package:fittrack/features/goals/data/reminder_repository.dart';
import 'package:fittrack/features/routines/domain/routine_models.dart';

class _Sched extends Mock implements NotificationScheduler {}

RoutineSummary _r(int id, String name, [int n = 3]) =>
    RoutineSummary(Routine(id: id, name: name, createdAt: DateTime(2026)), n);

void main() {
  late AppDatabase db;
  late _Sched sched;
  late ReminderRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    sched = _Sched();
    repo = ReminderRepository(db, sched);
    when(() => sched.scheduleWeekly(
        id: any(named: 'id'),
        weekday: any(named: 'weekday'),
        hour: any(named: 'hour'),
        minute: any(named: 'minute'))).thenAnswer((_) async {});
    when(() => sched.cancel(any())).thenAnswer((_) async {});
  });
  tearDown(() => db.close());

  test('permission denied saves and schedules nothing', () async {
    when(() => sched.requestPermission()).thenAnswer((_) async => false);
    expect(await repo.add({1, 3}, 18, 0), isFalse);
    expect(await repo.watchAll().first, isEmpty);
    verifyNever(() => sched.scheduleWeekly(
        id: any(named: 'id'), weekday: any(named: 'weekday'), hour: any(named: 'hour'), minute: any(named: 'minute')));
  });

  test('add schedules one per day; disable/delete cancel', () async {
    when(() => sched.requestPermission()).thenAnswer((_) async => true);
    expect(await repo.add({1, 3}, 18, 30), isTrue);
    final list = await repo.watchAll().first;
    expect(list.map((r) => r.weekday), [1, 3]);
    verify(() => sched.scheduleWeekly(id: list[0].id, weekday: 1, hour: 18, minute: 30)).called(1);

    await repo.setEnabled(list[0], false);
    verify(() => sched.cancel(list[0].id)).called(1);
    await repo.delete(list[1]);
    expect((await repo.watchAll().first).length, 1);
  });

  test('suggestRoutine rotates to the least recently trained, skipping empty ones', () {
    final routines = [_r(1, 'Pull'), _r(2, 'Push'), _r(3, 'Piernas'), _r(4, 'Vacía', 0)];
    expect(suggestRoutine(routines, {})!.routine.name, 'Piernas'); // never done, by name
    final done = {1: DateTime(2026, 6, 3), 2: DateTime(2026, 6, 1), 3: DateTime(2026, 6, 5)};
    expect(suggestRoutine(routines, done)!.routine.name, 'Push');
    expect(suggestRoutine([_r(4, 'Vacía', 0)], {}), isNull);
  });
}
