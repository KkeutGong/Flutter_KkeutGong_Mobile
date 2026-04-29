import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:kkeutgong_mobile/shared/styles/colors.dart';

/// Circular gauge that shows the current "합격 가능성 %" on the home hero.
/// Color shifts on threshold (red < 50, amber 50-75, green ≥ 75) so a
/// glance tells the user where they stand. Tapping the parent should open
/// a bottom sheet with the breakdown — this widget is purely visual.
class PassMeter extends StatelessWidget {
  final int value; // 0..100
  final double size;

  const PassMeter({super.key, required this.value, this.size = 96});

  Color _accent(int v) {
    if (v >= 75) return const Color(0xFF34C759);
    if (v >= 50) return const Color(0xFFFFC107);
    return const Color(0xFFFF6E6E);
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final clamped = value.clamp(0, 100);
    final accent = _accent(clamped);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _MeterPainter(
              progress: clamped / 100,
              trackColor: colors.gray0.withValues(alpha: 0.25),
              progressColor: accent,
              strokeWidth: 8,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$clamped',
                style: TextStyle(
                  fontFamily: 'SeoulAlrim',
                  fontSize: size * 0.32,
                  fontWeight: FontWeight.w800,
                  color: colors.gray0,
                  height: 1.0,
                ),
              ),
              Text(
                '합격 가능성',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: size * 0.10,
                  fontWeight: FontWeight.w600,
                  color: colors.gray0.withValues(alpha: 0.85),
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MeterPainter extends CustomPainter {
  final double progress; // 0..1
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  _MeterPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final fill = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      progress.clamp(0.0, 1.0) * 2 * math.pi,
      false,
      fill,
    );
  }

  @override
  bool shouldRepaint(covariant _MeterPainter old) =>
      old.progress != progress || old.progressColor != progressColor;
}
