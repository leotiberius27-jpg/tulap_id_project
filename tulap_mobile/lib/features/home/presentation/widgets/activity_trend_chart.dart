import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../dashboard/domain/entities/activity_trend_point.dart';

class ActivityTrendChart extends StatefulWidget {
  final List<ActivityTrendPoint> trendPoints;
  final ValueChanged<ActivityTrendPoint>? onPointTap;

  const ActivityTrendChart({
    super.key,
    required this.trendPoints,
    this.onPointTap,
  });

  @override
  State<ActivityTrendChart> createState() => _ActivityTrendChartState();
}

class _ActivityTrendChartState extends State<ActivityTrendChart> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.trendPoints.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxCount = widget.trendPoints.fold<int>(
      1,
      (max, p) => math.max(max, p.count),
    );
    final totalCount = widget.trendPoints.fold<int>(
      0,
      (sum, p) => sum + p.count,
    );

    final selectedPoint = _selectedIndex != null &&
            _selectedIndex! >= 0 &&
            _selectedIndex! < widget.trendPoints.length
        ? widget.trendPoints[_selectedIndex!]
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? const Color(0xFF334155)
                : AppColors.primary.withValues(alpha: 0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Flexible(
                  child: Text(
                    'Aktivitas Periode Ini',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$totalCount kegiatan',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (selectedPoint != null)
              InkWell(
                onTap: () => widget.onPointTap?.call(selectedPoint),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${selectedPoint.label} • ${selectedPoint.count} kegiatan',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_rounded, size: 12, color: AppColors.primary),
                    ],
                  ),
                ),
              )
            else
              const Text(
                'Ketuk titik atau batang untuk melihat rincian tanggal',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            const SizedBox(height: 14),

            // Chart area
            SizedBox(
              height: 110,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final count = widget.trendPoints.length;
                  final step = width / math.max(1, count);

                  return GestureDetector(
                    onTapDown: (details) {
                      final x = details.localPosition.dx;
                      final idx = (x / step).floor().clamp(0, count - 1);
                      setState(() {
                        _selectedIndex = idx;
                      });
                      widget.onPointTap?.call(widget.trendPoints[idx]);
                    },
                    child: CustomPaint(
                      size: Size(width, 110),
                      painter: _TrendChartPainter(
                        points: widget.trendPoints,
                        maxCount: maxCount,
                        selectedIndex: _selectedIndex,
                        isDark: isDark,
                        primaryColor: AppColors.primary,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  final List<ActivityTrendPoint> points;
  final int maxCount;
  final int? selectedIndex;
  final bool isDark;
  final Color primaryColor;

  _TrendChartPainter({
    required this.points,
    required this.maxCount,
    required this.selectedIndex,
    required this.isDark,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final count = points.length;
    final step = size.width / (count > 1 ? (count - 1) : 1);
    final chartHeight = size.height - 20;

    // Draw background guide lines
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06)
      ..strokeWidth = 1;

    canvas.drawLine(Offset.zero, Offset(size.width, 0), gridPaint);
    canvas.drawLine(Offset(0, chartHeight / 2), Offset(size.width, chartHeight / 2), gridPaint);
    canvas.drawLine(Offset(0, chartHeight), Offset(size.width, chartHeight), gridPaint);

    final path = Path();
    final fillPath = Path();
    final pointOffsets = <Offset>[];

    for (int i = 0; i < count; i++) {
      final x = count > 1 ? i * step : size.width / 2;
      final ratio = maxCount > 0 ? (points[i].count / maxCount) : 0.0;
      final y = chartHeight - (ratio * (chartHeight - 10));
      final offset = Offset(x, y);
      pointOffsets.add(offset);

      if (i == 0) {
        path.moveTo(offset.dx, offset.dy);
        fillPath.moveTo(offset.dx, chartHeight);
        fillPath.lineTo(offset.dx, offset.dy);
      } else {
        final prev = pointOffsets[i - 1];
        final controlX1 = prev.dx + (offset.dx - prev.dx) / 2;
        path.cubicTo(controlX1, prev.dy, controlX1, offset.dy, offset.dx, offset.dy);
        fillPath.cubicTo(controlX1, prev.dy, controlX1, offset.dy, offset.dx, offset.dy);
      }
    }

    if (pointOffsets.isNotEmpty) {
      fillPath.lineTo(pointOffsets.last.dx, chartHeight);
      fillPath.close();

      // Draw Gradient Area under Curve
      final gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          primaryColor.withValues(alpha: isDark ? 0.35 : 0.2),
          primaryColor.withValues(alpha: 0.0),
        ],
      );
      final fillPaint = Paint()
        ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, chartHeight));
      canvas.drawPath(fillPath, fillPaint);

      // Draw Line
      final linePaint = Paint()
        ..color = primaryColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, linePaint);

      // Draw Circles and selected highlight
      for (int i = 0; i < pointOffsets.length; i++) {
        final offset = pointOffsets[i];
        final isSelected = selectedIndex == i;

        if (points[i].count > 0 || isSelected) {
          final dotPaint = Paint()
            ..color = isSelected ? AppColors.warning : primaryColor
            ..style = PaintingStyle.fill;
          final borderPaint = Paint()
            ..color = isDark ? const Color(0xFF1E293B) : Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2;

          canvas.drawCircle(offset, isSelected ? 5.5 : 3.5, dotPaint);
          canvas.drawCircle(offset, isSelected ? 5.5 : 3.5, borderPaint);
        }
      }
    }

    // Draw date labels on bottom (every few points)
    final labelInterval = (count / 4).ceil().clamp(1, count);
    for (int i = 0; i < count; i += labelInterval) {
      final x = count > 1 ? i * step : size.width / 2;
      final textSpan = TextSpan(
        text: points[i].label,
        style: TextStyle(
          fontSize: 9,
          color: isDark ? const Color(0xFF94A3B8) : AppColors.textMuted,
        ),
      );
      final tp = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x.clamp(0.0, size.width - tp.width), size.height - 14));
    }
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.isDark != isDark;
  }
}
