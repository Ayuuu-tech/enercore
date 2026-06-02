import 'package:flutter/material.dart';

class LineChartPlaceholder extends StatelessWidget {
  const LineChartPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 200),
      painter: _MockChartPainter(Theme.of(context).colorScheme.primary),
    );
  }
}

class _MockChartPainter extends CustomPainter {
  final Color color;
  _MockChartPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height * 0.8);
    path.quadraticBezierTo(size.width * 0.2, size.height * 0.8, size.width * 0.3, size.height * 0.5);
    path.quadraticBezierTo(size.width * 0.5, size.height * 0.2, size.width * 0.7, size.height * 0.4);
    path.quadraticBezierTo(size.width * 0.8, size.height * 0.5, size.width, size.height * 0.1);

    canvas.drawPath(path, paint);
    
    // Draw fill
    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
      
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();
    
    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
