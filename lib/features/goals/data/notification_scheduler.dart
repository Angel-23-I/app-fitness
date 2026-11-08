import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../../l10n/gen/app_localizations.dart';

/// Boundary to the OS notification system, so reminders logic can be tested without it.
abstract class NotificationScheduler {
  Future<void> init();

  /// Asks for the notification permission; true when granted.
  Future<bool> requestPermission();

  /// Schedules a notification repeating every week on [weekday] (DateTime.monday..sunday).
  Future<void> scheduleWeekly({required int id, required int weekday, required int hour, required int minute});

  Future<void> cancel(int id);
}

class LocalNotificationScheduler implements NotificationScheduler {
  final _plugin = FlutterLocalNotificationsPlugin();

  @override
  Future<void> init() async {
    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation((await FlutterTimezone.getLocalTimezone()).identifier));
    } catch (_) {
      // Falls back to UTC; reminders would then be offset, but the app keeps working.
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // Permission is requested explicitly from the reminders screen, not at launch.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
  }

  @override
  Future<bool> requestPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      return await android?.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    return await ios?.requestPermissions(alert: true, badge: true, sound: true) ?? false;
  }

  @override
  Future<void> scheduleWeekly(
      {required int id, required int weekday, required int hour, required int minute}) async {
    final l10n = lookupAppLocalizations(const Locale('es'));
    final now = tz.TZDateTime.now(tz.local);
    var when = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    while (when.weekday != weekday || !when.isAfter(now)) {
      when = when.add(const Duration(days: 1));
    }
    await _plugin.zonedSchedule(
      id: id,
      title: l10n.reminderNotificationTitle,
      body: l10n.reminderNotificationBody,
      scheduledDate: when,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails('workout_reminders', l10n.remindersTitle,
            importance: Importance.high, priority: Priority.high),
        iOS: const DarwinNotificationDetails(),
      ),
      // Inexact avoids the special "exact alarm" permission; a few minutes of drift is fine here.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  @override
  Future<void> cancel(int id) => _plugin.cancel(id: id);
}

final notificationSchedulerProvider =
    Provider<NotificationScheduler>((ref) => LocalNotificationScheduler());
