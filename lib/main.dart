import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'features/goals/data/notification_scheduler.dart';
import 'features/goals/data/reminder_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();
  try {
    await container.read(notificationSchedulerProvider).init();
    unawaited(container.read(reminderRepositoryProvider).syncAll());
  } catch (e) {
    debugPrint('Notifications unavailable: $e');
  }
  runApp(UncontrolledProviderScope(container: container, child: const FitTrackApp()));
}
