import 'package:flutter/material.dart';
import 'package:kkeutgong_mobile/data/repositories/study/pass_trend_repository.dart';
import 'package:kkeutgong_mobile/shared/styles/colors.dart';
import 'package:kkeutgong_mobile/shared/styles/typography.dart';

/// Self-loading mini trend chart: spawns its own /study/pass-trend fetch
/// when the bottom sheet opens, then paints a tight Y=[0..100] line over
/// the last 30 daily snapshots. Empty/short series fall back to a stub
/// "데이터 쌓이는 중" message so first-day users see something useful.
class PassTrendChart extends StatefulWidget {
  final double height;

  const PassTrendChart({super.key, this.height = 96});

  @override
  State<PassTrendChart> createState() => _PassTrendChartState();
}

class _PassTrendChartState extends State<PassTrendChart> {
  final PassTrendRepository _repo = PassTrendRepository();
  bool _loading = true;
  List<PassTrendPoint> _points = const [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await _repo.getTrend();
      if (!mounted) return;
      setState(() {
        _points = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '추이를 불러오지 못했어요';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    if (_loading) {
      return SizedBox(
        height: widget.height,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(colors.primaryNormal),
            ),
          ),
        ),
      );
    }
    if (_error != null) {
      return SizedBox(
        height: widget.height,
        child: Center(
          child: Text(
            _error!,
            style: Typo.labelRegular(context, color: colors.gray500),
          ),
        ),
      );
    }
    if (_points.length < 2) {
      return SizedBox(
        height: widget.height,
        child: Center(
          child: Text(
            '데이터가 쌓이는 중이에요',
            style: Typo.labelRegular(context, color: colors.gray500),
          ),
        ),
      );
    }

    final latest = _points.last.value;
    final earliest = _points.first.value;
    final delta = latest - earliest;
    final deltaText = delta == 0
        ? '시작 이후 변화 없음'
        : (delta > 0 ? '시작 대비 +$delta점' : '시작 대비 $delta점');
    final accent = delta >= 0 ? const Color(0xFF34C759) : const Color(0xFFFF6E6E);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '$latest%',
              style: TextStyle(
                fontFamily: 'SeoulAlrim',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: colors.gray900,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              deltaText,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: widget.height,
          child: CustomPaint(
            painter: _TrendPainter(
              points: _points,
              gridColor: colors.gray30,
              lineColor: accent,
              fillColor: accent.withValues(alpha: 0.10),
            ),
            size: Size.infinite,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${_points.first.date.month}/${_points.first.date.day} → ${_points.last.date.month}/${_points.last.date.day}',
          style: Typo.labelRegular(context, color: colors.gray400),
        ),
      ],
    );
  }
}

class _TrendPainter extends CustomPainter {
  final List<PassTrendPoint> points;
  final Color gridColor;
  final Color lineColor;
  final Color fillColor;

  _TrendPainter({
    required this.points,
    required this.gridColor,
    required this.lineColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    // Y axis fixed 0..100. Grid at 0/50/100.
    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    final dyMid = size.height * 0.5;
    canvas.drawLine(Offset(0, 0), Offset(size.width, 0), grid);
    canvas.drawLine(Offset(0, dyMid), Offset(size.width, dyMid), grid);
    canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), grid);

    final stepX = size.width / (points.length - 1);
    Offset pointFor(int i) {
      final v = points[i].value.clamp(0, 100);
      final y = size.height - (v / 100) * size.height;
      return Offset(i * stepX, y);
    }

    final path = Path();
    final fillPath = Path();
    final first = pointFor(0);
    path.moveTo(first.dx, first.dy);
    fillPath.moveTo(first.dx, size.height);
    fillPath.lineTo(first.dx, first.dy);
    for (int i = 1; i < points.length; i++) {
      final p = pointFor(i);
      path.lineTo(p.dx, p.dy);
      fillPath.lineTo(p.dx, p.dy);
    }
    final last = pointFor(points.length - 1);
    fillPath.lineTo(last.dx, size.height);
    fillPath.close();

    final fill = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fill);

    final line = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, line);

    // Last-point marker
    final marker = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(last, 4, marker);
    final markerRing = Paint()
      ..color = lineColor.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(last, 8, markerRing);
  }

  @override
  bool shouldRepaint(covariant _TrendPainter old) =>
      old.points != points || old.lineColor != lineColor;
}
