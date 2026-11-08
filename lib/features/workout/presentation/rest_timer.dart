import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/gen/app_localizations.dart';

/// End time of the running rest countdown, or null when idle.
class RestTimer extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;

  void start(int seconds) => state = DateTime.now().add(Duration(seconds: seconds));
  void add(int seconds) => state = state?.add(Duration(seconds: seconds));
  void stop() => state = null;
}

final restTimerProvider = NotifierProvider<RestTimer, DateTime?>(RestTimer.new);

class RestTimerBar extends ConsumerStatefulWidget {
  const RestTimerBar({super.key});

  @override
  ConsumerState<RestTimerBar> createState() => _RestTimerBarState();
}

class _RestTimerBarState extends ConsumerState<RestTimerBar> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      final end = ref.read(restTimerProvider);
      if (end == null) return;
      if (!end.isAfter(DateTime.now())) {
        ref.read(restTimerProvider.notifier).stop();
        HapticFeedback.heavyImpact();
      } else {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final end = ref.watch(restTimerProvider);
    if (end == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final left = end.difference(DateTime.now()).inSeconds.clamp(0, 99999);
    final text = '${(left ~/ 60).toString().padLeft(2, '0')}:${(left % 60).toString().padLeft(2, '0')}';
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primaryContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            Icon(Icons.timer_outlined, color: scheme.onPrimaryContainer),
            const SizedBox(width: 8),
            Text('${l10n.restTimer} $text',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: scheme.onPrimaryContainer)),
            const Spacer(),
            TextButton(
                onPressed: () => ref.read(restTimerProvider.notifier).add(15),
                child: const Text('+15 s')),
            TextButton(
                onPressed: () => ref.read(restTimerProvider.notifier).stop(),
                child: Text(l10n.restSkip)),
          ]),
        ),
      ),
    );
  }
}
