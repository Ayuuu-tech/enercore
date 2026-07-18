import 'package:flutter/material.dart';

/// One line on an [InteractiveMultiLineChart].
class ChartLine {
  final List<double> values;
  final Color color;
  final String label;
  final String unit;
  const ChartLine({
    required this.values,
    required this.color,
    required this.label,
    this.unit = '',
  });
}

/// Several lines sharing one time axis, each scaled to its own range so lines
/// with very different magnitudes (volts vs amps) are both readable. Scrub
/// across it and a tooltip reads every line's value at that moment.
class InteractiveMultiLineChart extends StatefulWidget {
  final List<DateTime> times;
  final List<ChartLine> lines;
  final double height;

  const InteractiveMultiLineChart({
    super.key,
    required this.times,
    required this.lines,
    this.height = 120,
  });

  @override
  State<InteractiveMultiLineChart> createState() => _InteractiveMultiLineChartState();
}

class _InteractiveMultiLineChartState extends State<InteractiveMultiLineChart> {
  int? _active;

  static const _slateDark = Color(0xFF1E293B);

  int get _len => widget.lines.isEmpty ? 0 : widget.lines.first.values.length;

  void _updateFromX(double dx, double width) {
    if (_len < 2) return;
    final t = (dx / width).clamp(0.0, 1.0);
    final idx = (t * (_len - 1)).round();
    if (idx != _active) setState(() => _active = idx);
  }

  String _time(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => _updateFromX(d.localPosition.dx, w),
          onHorizontalDragStart: (d) => _updateFromX(d.localPosition.dx, w),
          onHorizontalDragUpdate: (d) => _updateFromX(d.localPosition.dx, w),
          onTapUp: (_) => setState(() => _active = null),
          onHorizontalDragEnd: (_) => setState(() => _active = null),
          onTapCancel: () => setState(() => _active = null),
          child: SizedBox(
            height: widget.height,
            width: double.infinity,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CustomPaint(
                  size: Size(w, widget.height),
                  painter: _MultiLinePainter(lines: widget.lines, active: _active),
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
    const bubbleW = 130.0;
    final x = (i / (_len - 1)) * width;
    final left = (x - bubbleW / 2).clamp(0.0, width - bubbleW);

    return Positioned(
      left: left,
      top: -6,
      child: IgnorePointer(
        child: Container(
          width: bubbleW,
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          decoration: BoxDecoration(
            color: _slateDark,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (i < widget.times.length)
                Text(_time(widget.times[i]),
                    style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              for (final l in widget.lines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 1),
                  child: Row(
                    children: [
                      Container(width: 7, height: 7,
                          decoration: BoxDecoration(color: l.color, shape: BoxShape.circle)),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(l.label,
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white70, fontSize: 9)),
                      ),
                      Text(
                        '${(i < l.values.length ? l.values[i] : 0).toStringAsFixed(1)}${l.unit.isEmpty ? '' : ' ${l.unit}'}',
                        style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MultiLinePainter extends CustomPainter {
  final List<ChartLine> lines;
  final int? active;

  _MultiLinePainter({required this.lines, this.active});

  @override
  void paint(Canvas canvas, Size size) {
    const pad = 6.0;
    final h = size.height - pad * 2;

    for (final line in lines) {
      final v = line.values;
      if (v.length < 2) continue;
      final maxV = v.reduce((a, b) => a > b ? a : b);
      final minV = v.reduce((a, b) => a < b ? a : b);
      final range = (maxV - minV).abs() < 1e-6 ? 1.0 : maxV - minV;

      Offset pt(int i) => Offset(
            (i / (v.length - 1)) * size.width,
            pad + h - ((v[i] - minV) / range) * h,
          );

      final path = Path()..moveTo(pt(0).dx, pt(0).dy);
      for (int i = 1; i < v.length; i++) {
        path.lineTo(pt(i).dx, pt(i).dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = line.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    // Shared scrub guide + a dot on each line.
    final n = lines.isEmpty ? 0 : lines.first.values.length;
    if (active != null && n >= 2 && active! < n) {
      final gx = (active! / (n - 1)) * size.width;
      canvas.drawLine(
        Offset(gx, 0),
        Offset(gx, size.height),
        Paint()
          ..color = const Color(0xFF94A3B8).withValues(alpha: 0.5)
          ..strokeWidth = 1,
      );
      for (final line in lines) {
        final v = line.values;
        if (v.length < 2 || active! >= v.length) continue;
        final maxV = v.reduce((a, b) => a > b ? a : b);
        final minV = v.reduce((a, b) => a < b ? a : b);
        final range = (maxV - minV).abs() < 1e-6 ? 1.0 : maxV - minV;
        final y = pad + h - ((v[active!] - minV) / range) * h;
        canvas.drawCircle(Offset(gx, y), 4.5, Paint()..color = Colors.white);
        canvas.drawCircle(Offset(gx, y), 3.2, Paint()..color = line.color);
      }
    }
  }

  @override
  bool shouldRepaint(_MultiLinePainter old) => old.lines != lines || old.active != active;
}
