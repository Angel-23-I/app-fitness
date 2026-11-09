import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Big italic uppercase screen title with optional trailing actions; used by the tab screens.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({super.key, required this.title, this.overline, this.actions = const []});

  final String title;
  final String? overline;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (overline != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(overline!.toUpperCase(),
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.4, color: AppColors.muted)),
                ),
              Semantics(
                header: true,
                child: Text(title.toUpperCase(), style: display(40, italic: true)),
              ),
            ]),
          ),
          ...actions,
        ]),
      );
}

/// Square accent action button for headers (44 px touch target).
class HeaderAction extends StatelessWidget {
  const HeaderAction({super.key, required this.icon, required this.tooltip, required this.onPressed, this.filled = false});

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 8),
        child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          icon: Icon(icon),
          style: IconButton.styleFrom(
            fixedSize: const Size(44, 44),
            backgroundColor: filled ? AppColors.accent : AppColors.surface,
            foregroundColor: filled ? AppColors.bg : AppColors.text,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: filled ? BorderSide.none : const BorderSide(color: AppColors.border),
            ),
          ),
        ),
      );
}

/// Bordered dark panel, the base card of the design.
class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.radius = 24, this.color, this.onTap});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: const BorderSide(color: AppColors.border),
    );
    return Material(
      color: color ?? AppColors.surface,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
    );
  }
}

/// Small rounded label, e.g. "SUGERIDO HOY".
class Tag extends StatelessWidget {
  const Tag(this.text, {super.key, this.color = AppColors.accent, this.foreground = AppColors.bg});

  final String text;
  final Color color, foreground;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
        child: Text(text.toUpperCase(),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.1, color: foreground)),
      );
}

/// Thin rounded progress bar.
class ThinBar extends StatelessWidget {
  const ThinBar({super.key, required this.value, this.color = AppColors.lime, this.height = 6});

  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: LinearProgressIndicator(
          value: value.clamp(0, 1).toDouble(),
          minHeight: height,
          color: color,
          backgroundColor: AppColors.surfaceHigh,
        ),
      );
}

/// Diagonal stripes standing in for exercise artwork behind hero cards.
class StripeBackground extends StatelessWidget {
  const StripeBackground({super.key, this.child});
  final Widget? child;

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _StripePainter(), child: child);
}

class _StripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF1B1E26));
    final p = Paint()
      ..color = const Color(0xFF232631)
      ..strokeWidth = 12;
    for (var x = -size.height; x < size.width + size.height; x += 34) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// One ring of [ActivityRings]: progress 0..1 and its color.
class Ring {
  const Ring(this.value, this.color, {this.track});
  final double value;
  final Color color;

  /// Track behind the arc; defaults to a dark tint of [color].
  final Color? track;
}

/// Concentric activity rings, outermost first.
class ActivityRings extends StatelessWidget {
  const ActivityRings({super.key, required this.rings, this.size = 112, this.stroke = 10, this.semanticsLabel, this.center});

  final List<Ring> rings;
  final double size, stroke;
  final String? semanticsLabel;
  final Widget? center;

  @override
  Widget build(BuildContext context) => Semantics(
        label: semanticsLabel,
        child: SizedBox.square(
          dimension: size,
          child: CustomPaint(
            painter: _RingsPainter(rings, stroke),
            child: center == null ? null : Center(child: center),
          ),
        ),
      );
}

class _RingsPainter extends CustomPainter {
  _RingsPainter(this.rings, this.stroke);
  final List<Ring> rings;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    var r = size.shortestSide / 2 - stroke / 2;
    for (final ring in rings) {
      final track = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = ring.track ?? Color.alphaBlend(ring.color.withValues(alpha: 0.16), AppColors.bg);
      canvas.drawCircle(c, r, track);
      final v = ring.value.clamp(0, 1).toDouble();
      if (v > 0) {
        final arc = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..color = ring.color;
        canvas.drawArc(Rect.fromCircle(center: c, radius: r), -math.pi / 2, 2 * math.pi * v, false, arc);
      }
      r -= stroke + 3;
    }
  }

  @override
  bool shouldRepaint(_RingsPainter old) => old.rings != rings || old.stroke != stroke;
}

/// Big display number with a small muted unit after it.
class BigValue extends StatelessWidget {
  const BigValue(this.value, {super.key, this.unit, this.size = 30, this.color});

  final String value;
  final String? unit;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => Text.rich(TextSpan(children: [
        TextSpan(text: value, style: display(size, color: color, weight: FontWeight.w700)),
        if (unit != null)
          TextSpan(text: ' $unit', style: display(size * 0.55, color: AppColors.muted, weight: FontWeight.w600)),
      ]));
}
