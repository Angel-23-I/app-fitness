import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/fit_widgets.dart';
import '../../../l10n/gen/app_localizations.dart';

/// End time of the running rest countdown, or null when idle.
class RestTimer extends Notifier<DateTime?> {
  /// Length of the current countdown in seconds, for the progress ring.
  int total = 0;

  @override
  DateTime? build() => null;

  void start(int seconds) {
    total = seconds;
    state = DateTime.now().add(Duration(seconds: seconds));
  }

  void add(int seconds) {
    final end = state;
    if (end == null) return;
    final next = end.add(Duration(seconds: seconds));
    if (!next.isAfter(DateTime.now())) {
      stop();
      return;
    }
    if (seconds > 0) total += seconds;
    state = next;
  }

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
    final notifier = ref.read(restTimerProvider.notifier);
    final left = end.difference(DateTime.now()).inSeconds.clamp(0, 99999);
    final text = '${(left ~/ 60).toString().padLeft(2, '0')}:${(left % 60).toString().padLeft(2, '0')}';
    final total = notifier.total <= 0 ? left : notifier.total;
    const ink = AppColors.bg;
    ButtonStyle small(Color bg, Color fg) => FilledButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        );
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          decoration: BoxDecoration(
            color: AppColors.text,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 32, offset: Offset(0, -8))],
          ),
          child: Row(children: [
            ActivityRings(
              size: 56,
              stroke: 6,
              rings: [Ring(total == 0 ? 0 : left / total, AppColors.accent, track: const Color(0xFFDADDE3))],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(l10n.restTimer.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: Color(0xFF5B616E))),
                Text(text,
                    style: display(34, color: ink).copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
              ]),
            ),
            FilledButton(
                onPressed: () => notifier.add(-15), style: small(const Color(0xFFDADDE3), ink), child: const Text('-15')),
            const SizedBox(width: 6),
            FilledButton(
                onPressed: () => notifier.add(15), style: small(const Color(0xFFDADDE3), ink), child: const Text('+15')),
            const SizedBox(width: 6),
            FilledButton(onPressed: notifier.stop, style: small(ink, AppColors.text), child: Text(l10n.restSkip)),
          ]),
        ),
      ),
    );
  }
}
