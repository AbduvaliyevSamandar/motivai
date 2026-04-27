import 'package:flutter/material.dart';

/// Google's official multi-color "G" logo, drawn with CustomPainter so we
/// don't have to ship a PNG/SVG. Approximates the brand mark's 4 arcs.
class GoogleLogo extends StatelessWidget {
  final double size;
  const GoogleLogo({super.key, this.size = 22});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  static const _blue = Color(0xFF4285F4);
  static const _green = Color(0xFF34A853);
  static const _yellow = Color(0xFFFBBC05);
  static const _red = Color(0xFFEA4335);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final stroke = s * 0.18;
    final r = (s - stroke) / 2;
    final c = Offset(s / 2, s / 2);
    final rect = Rect.fromCircle(center: c, radius: r);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    // Each arc covers ~90deg, mapped to the 4 brand colors.
    canvas.drawArc(rect, _deg(-22), _deg(72), false, paint..color = _blue);
    canvas.drawArc(rect, _deg(50), _deg(80), false, paint..color = _green);
    canvas.drawArc(rect, _deg(130), _deg(85), false, paint..color = _yellow);
    canvas.drawArc(rect, _deg(215), _deg(110), false, paint..color = _red);

    // Horizontal bar that completes the "G" shape, in blue.
    final barPaint = Paint()..color = _blue;
    final barRect = Rect.fromLTWH(
      c.dx + r * 0.05,
      c.dy - stroke / 2,
      r * 0.95,
      stroke,
    );
    canvas.drawRect(barRect, barPaint);
  }

  double _deg(double d) => d * 3.141592653589793 / 180.0;

  @override
  bool shouldRepaint(_) => false;
}
