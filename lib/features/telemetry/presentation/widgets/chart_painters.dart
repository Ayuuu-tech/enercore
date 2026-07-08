import 'dart:math' as math;
import 'package:flutter/material.dart';

Path _smoothPath(List<Offset> pts) {
  final path = Path();
  path.moveTo(pts[0].dx, pts[0].dy);
  for (int i = 0; i < pts.length - 1; i++) {
    final cp1 = Offset((pts[i].dx + pts[i + 1].dx) / 2, pts[i].dy);
    final cp2 = Offset((pts[i].dx + pts[i + 1].dx) / 2, pts[i + 1].dy);
    path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, pts[i + 1].dx, pts[i + 1].dy);
  }
  return path;
}

/// Normalise values into 10%–90% of the height so flat lines stay visible.
List<Offset> _normalisedPoints(List<double> values, Size size) {
  final minV = values.reduce(math.min);
  final maxV = values.reduce(math.max);
  final range = (maxV - minV).abs() < 1e-9 ? 1.0 : maxV - minV;
  return [
    for (int i = 0; i < values.length; i++)
      Offset(
        size.width * i / (values.length - 1),
        size.height * (0.9 - 0.8 * (values[i] - minV) / range),
      ),
  ];
}

/// Solid voltage line + dashed current line (solar-grid "Voltage & Current").
class TelemetryChartPainter extends CustomPainter {
  final List<double> voltage;
  final List<double> current;
  const TelemetryChartPainter({required this.voltage, required this.current});

  @override
  void paint(Canvas canvas, Size size) {
    if (voltage.length < 2) return;

    final vPaint = Paint()
      ..color = const Color(0xFF2A8C6E)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(_smoothPath(_normalisedPoints(voltage, size)), vPaint);

    final cPaint = Paint()
      ..color = const Color(0xFF2A8C6E).withValues(alpha: 0.6)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    _drawDashedPath(canvas, _smoothPath(_normalisedPoints(current, size)), cPaint);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double distance = 0.0;
    for (final metric in path.computeMetrics()) {
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + dashWidth), paint);
        distance += dashWidth + dashSpace;
      }
      distance = 0.0;
    }
  }

  @override
  bool shouldRepaint(covariant TelemetryChartPainter old) =>
      old.voltage != voltage || old.current != current;
}

/// Small legend swatch — solid or dashed line.
class LineLegendPainter extends CustomPainter {
  final bool isSolid;
  final Color color;
  const LineLegendPainter({required this.isSolid, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    final y = size.height / 2;
    if (isSolid) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    } else {
      canvas.drawLine(Offset(0, y), Offset(4, y), paint);
      canvas.drawLine(Offset(8, y), Offset(12, y), paint);
      canvas.drawLine(Offset(16, y), Offset(20, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Two smoothed series (telemetry "Phase Characteristics").
class PhaseChartPainter extends CustomPainter {
  final List<double> voltage;
  final List<double> current;
  const PhaseChartPainter({required this.voltage, required this.current});

  @override
  void paint(Canvas canvas, Size size) {
    if (voltage.length < 2) return;
    _draw(canvas, size, voltage, const Color(0xFF0D9488));
    _draw(canvas, size, current, const Color(0xFF2A8C6E).withValues(alpha: 0.5));
  }

  void _draw(Canvas canvas, Size size, List<double> values, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(_smoothPath(_normalisedPoints(values, size)), paint);
  }

  @override
  bool shouldRepaint(covariant PhaseChartPainter old) =>
      old.voltage != voltage || old.current != current;
}

/// Compact bar sparkline for the metric cards.
class SparklinePainter extends CustomPainter {
  final List<double> values;
  const SparklinePainter({required this.values});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final paint = Paint()
      ..color = const Color(0xFF0D9488)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final shown = values.length > 7 ? values.sublist(values.length - 7) : values;
    final minV = shown.reduce(math.min);
    final maxV = shown.reduce(math.max);
    final range = (maxV - minV).abs() < 1e-9 ? 1.0 : maxV - minV;
    final spacing = shown.length > 1 ? size.width / (shown.length - 1) : 0.0;

    for (int i = 0; i < shown.length; i++) {
      final x = i * spacing;
      final norm = 0.2 + 0.8 * (shown[i] - minV) / range;
      canvas.drawLine(Offset(x, size.height), Offset(x, size.height * (1.0 - norm)), paint);
    }
  }

  @override
  bool shouldRepaint(covariant SparklinePainter old) => old.values != values;
}
