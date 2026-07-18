import 'package:flutter/material.dart';

/// Grouped daily bar chart — one group per day, one bar per device — with a
/// tap/scrub readout, like the "generation by inverter" chart on the portals.
class GroupedBarChart extends StatefulWidget {
  /// Device names, in the order their values appear in each day's [values].
  final List<String> series;

  /// One entry per day: the x-axis label and a value per device.
  final List<GroupedBarDay> days;

  final String unit;
  final double height;

  const GroupedBarChart({
    super.key,
    required this.series,
    required this.days,
    this.unit = 'kWh',
    this.height = 200,
  });

  @override
  State<GroupedBarChart> createState() => _GroupedBarChartState();
}

class GroupedBarDay {
  final String label; // x-axis label, e.g. "12 Jul"
  final List<double> values; // aligned to series
  const GroupedBarDay({required this.label, required this.values});
}

// A calm, distinguishable palette; the brand teal leads.
const _barPalette = <Color>[
  Color(0xFF2A8C6E),
  Color(0xFF334155),
  Color(0xFFF5A623),
  Color(0xFF3B82F6),
  Color(0xFF9333EA),
  Color(0xFFEF4444),
];

class _GroupedBarChartState extends State<GroupedBarChart> {
  int? _active;

  static const _slateDark = Color(0xFF1E293B);
  static const _slateLight = Color(0xFF64748B);

  Color _color(int i) => _barPalette[i % _barPalette.length];

  void _updateFromX(double dx, double width) {
    if (widget.days.isEmpty) return;
    final i = (dx / width * widget.days.length).floor().clamp(0, widget.days.length - 1);
    if (i != _active) setState(() => _active = i);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.days.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: const Center(
          child: Text('No generation recorded yet',
              style: TextStyle(color: _slateLight, fontSize: 12)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _legend(),
        const SizedBox(height: 10),
        LayoutBuilder(
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
                      painter: _BarPainter(
                        days: widget.days,
                        seriesCount: widget.series.length,
                        colorOf: _color,
                        active: _active,
                      ),
                    ),
                    if (_active != null) _tooltip(w),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        _xLabels(),
      ],
    );
  }

  Widget _legend() {
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        for (int i = 0; i < widget.series.length; i++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 10, height: 10,
                  decoration: BoxDecoration(color: _color(i), borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 5),
              Text(widget.series[i],
                  style: const TextStyle(color: _slateLight, fontSize: 10.5, fontWeight: FontWeight.w600)),
            ],
          ),
      ],
    );
  }

  Widget _xLabels() {
    // Thin the labels if they'd crowd; always show first and last.
    final n = widget.days.length;
    final step = (n / 6).ceil().clamp(1, n);
    return Row(
      children: [
        for (int i = 0; i < n; i++)
          Expanded(
            child: (i % step == 0 || i == n - 1)
                ? Text(widget.days[i].label,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.visible,
                    style: const TextStyle(color: _slateLight, fontSize: 8.5, fontWeight: FontWeight.w500))
                : const SizedBox.shrink(),
          ),
      ],
    );
  }

  Widget _tooltip(double width) {
    final i = _active!;
    final day = widget.days[i];
    final groupW = width / widget.days.length;
    const bubbleW = 132.0;
    final left = (groupW * i + groupW / 2 - bubbleW / 2).clamp(0.0, width - bubbleW);

    return Positioned(
      left: left,
      top: -4,
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
              Text(day.label,
                  style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              for (int s = 0; s < widget.series.length; s++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 1),
                  child: Row(
                    children: [
                      Container(width: 7, height: 7,
                          decoration: BoxDecoration(color: _color(s), shape: BoxShape.circle)),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(widget.series[s],
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white70, fontSize: 9)),
                      ),
                      Text('${day.values[s].toStringAsFixed(0)} ${widget.unit}',
                          style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w800)),
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

class _BarPainter extends CustomPainter {
  final List<GroupedBarDay> days;
  final int seriesCount;
  final Color Function(int) colorOf;
  final int? active;

  _BarPainter({
    required this.days,
    required this.seriesCount,
    required this.colorOf,
    this.active,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (days.isEmpty || seriesCount == 0) return;

    double maxV = 0;
    for (final d in days) {
      for (final v in d.values) {
        if (v > maxV) maxV = v;
      }
    }
    if (maxV <= 0) maxV = 1;

    const topPad = 6.0;
    final chartH = size.height - topPad;
    final groupW = size.width / days.length;
    final groupPad = groupW * 0.16;
    final barsW = groupW - groupPad * 2;
    final barW = barsW / seriesCount;

    // Faint baseline.
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      Paint()..color = const Color(0xFFE5E7EB),
    );

    for (int g = 0; g < days.length; g++) {
      final gx = groupW * g + groupPad;
      final dim = active != null && active != g;
      for (int s = 0; s < seriesCount; s++) {
        final v = s < days[g].values.length ? days[g].values[s] : 0.0;
        final h = (v / maxV) * chartH;
        final x = gx + barW * s;
        final rect = RRect.fromRectAndCorners(
          Rect.fromLTWH(x + 0.5, size.height - h, barW - 1, h),
          topLeft: const Radius.circular(2),
          topRight: const Radius.circular(2),
        );
        canvas.drawRRect(
          rect,
          Paint()..color = colorOf(s).withValues(alpha: dim ? 0.35 : 1.0),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_BarPainter old) => old.days != days || old.active != active;
}
