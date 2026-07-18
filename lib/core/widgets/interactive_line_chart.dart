import 'package:flutter/material.dart';

/// A line/area chart you can scrub: touch or drag across it and a guide line,
/// a highlighted point and a tooltip follow your finger — the same "hover to
/// read the value" interaction the monitoring portals have.
class InteractiveLineChart extends StatefulWidget {
  final List<double> values;
  final List<DateTime> times;
  final Color color;

  /// Unit suffix shown in the tooltip value, e.g. "kW".
  final String unit;
  final double height;

  const InteractiveLineChart({
    super.key,
    required this.values,
    required this.times,
    required this.color,
    this.unit = '',
    this.height = 120,
  });

  @override
  State<InteractiveLineChart> createState() => _InteractiveLineChartState();
}

class _InteractiveLineChartState extends State<InteractiveLineChart> {
  int? _active;

  static const _slateDark = Color(0xFF1E293B);

  void _updateFromX(double dx, double width) {
    if (widget.values.length < 2) return;
    final t = (dx / width).clamp(0.0, 1.0);
    final idx = (t * (widget.values.length - 1)).round();
    if (idx != _active) setState(() => _active = idx);
  }

  String _fmtTime(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _fmtValue(double v) {
    final s = v >= 100 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
    return widget.unit.isEmpty ? s : '$s ${widget.unit}';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => _updateFromX(d.localPosition.dx, w),
          onHorizontalDragStart: (d) => _updateFromX(d.localPosition.dx, w),
          onHorizontalDragUpdate: (d) => _updateFromX(d.localPosition.dx, w),
          // Let go and the readout clears, so the chart isn't left with a
          // stale marker.
          onHorizontalDragEnd: (_) => setState(() => _active = null),
          onTapUp: (_) => setState(() => _active = null),
          onTapCancel: () => setState(() => _active = null),
          child: SizedBox(
            height: widget.height,
            width: double.infinity,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CustomPaint(
                  size: Size(w, widget.height),
                  painter: _LineChartPainter(
                    values: widget.values,
                    color: widget.color,
                    active: _active,
                  ),
                ),
                if (_active != null) _tooltip(w),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _tooltip(double width) {
    final i = _active!;
    final n = widget.values.length;
    final x = (i / (n - 1)) * width;
    // Keep the bubble on-screen at both ends.
    const bubbleW = 116.0;
    final left = (x - bubbleW / 2).clamp(0.0, width - bubbleW);

    return Positioned(
      left: left,
      top: -6,
      child: IgnorePointer(
        child: Container(
          width: bubbleW,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: _slateDark,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 8),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(_fmtTime(widget.times[i]),
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w600)),
              const SizedBox(height: 1),
              Text(_fmtValue(widget.values[i]),
                  style: TextStyle(
                      color: widget.color == const Color(0xFF2A8C6E)
                          ? const Color(0xFF8FE3C8)
                          : Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final int? active;

  _LineChartPainter({required this.values, required this.color, this.active});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final maxV = values.reduce((a, b) => a > b ? a : b);
    final minV = values.reduce((a, b) => a < b ? a : b);
    final range = (maxV - minV).abs() < 1e-6 ? 1.0 : maxV - minV;
    const pad = 8.0;
    final h = size.height - pad * 2;

    Offset pt(int i) {
      final x = (i / (values.length - 1)) * size.width;
      final y = pad + h - ((values[i] - minV) / range) * h;
      return Offset(x, y);
    }

    // Filled area under the line.
    final area = Path()..moveTo(0, size.height);
    for (int i = 0; i < values.length; i++) {
      final p = pt(i);
      area.lineTo(p.dx, p.dy);
    }
    area.lineTo(size.width, size.height);
    area.close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.18), color.withValues(alpha: 0.0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // The line itself.
    final line = Path()..moveTo(pt(0).dx, pt(0).dy);
    for (int i = 1; i < values.length; i++) {
      line.lineTo(pt(i).dx, pt(i).dy);
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Scrub marker: a vertical guide and a ringed dot at the active point.
    if (active != null && active! >= 0 && active! < values.length) {
      final p = pt(active!);
      canvas.drawLine(
        Offset(p.dx, 0),
        Offset(p.dx, size.height),
        Paint()
          ..color = color.withValues(alpha: 0.35)
          ..strokeWidth = 1,
      );
      canvas.drawCircle(p, 5, Paint()..color = Colors.white);
      canvas.drawCircle(p, 4, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_LineChartPainter old) =>
      old.values != values || old.active != active;
}
