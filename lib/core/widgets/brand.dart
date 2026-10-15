import 'package:flutter/material.dart';

import '../theme/vault_palette.dart';

/// The house-and-dial mark from the splash and sign-in screens.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 128});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Home Vault',
      image: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: context.palette.primary,
          borderRadius: BorderRadius.circular(size * 0.28),
        ),
        child: CustomPaint(painter: _HousePainter()),
      ),
    );
  }
}

class _HousePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.045
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final house = Path()
      ..moveTo(s * 0.28, s * 0.46)
      ..lineTo(s * 0.5, s * 0.28)
      ..lineTo(s * 0.72, s * 0.46)
      ..lineTo(s * 0.72, s * 0.72)
      ..lineTo(s * 0.28, s * 0.72)
      ..close();
    canvas.drawPath(house, stroke);
    final c = Offset(s * 0.5, s * 0.555);
    canvas.drawCircle(c, s * 0.075, stroke);
    for (final d in [
      Offset(0, -s * 0.11),
      Offset(0, s * 0.11),
      Offset(-s * 0.11, 0),
      Offset(s * 0.11, 0),
    ]) {
      canvas.drawCircle(c + d, s * 0.012, stroke..style = PaintingStyle.fill);
      stroke.style = PaintingStyle.stroke;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Logo and wordmark above the sign-in and create-account titles.
class BrandRow extends StatelessWidget {
  const BrandRow({super.key, this.light = false});

  final bool light;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const BrandMark(size: 36),
      const SizedBox(width: 10),
      Flexible(
        child: Text(
          'Home Vault',
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: light ? Colors.white : context.palette.ink,
          ),
        ),
      ),
    ],
  );
}

/// The "G" for Continue with Google, drawn so no asset is needed.
class GoogleMark extends StatelessWidget {
  const GoogleMark({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _GPainter()),
  );
}

class _GPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromLTWH(
      size.width * 0.12,
      size.height * 0.12,
      size.width * 0.76,
      size.height * 0.76,
    );
    final w = size.width * 0.18;
    Paint p(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = w;
    const pi = 3.1415926;
    canvas
      ..drawArc(r, -pi * 0.25, -pi * 0.5, false, p(const Color(0xFFEA4335)))
      ..drawArc(r, -pi * 0.75, -pi * 0.5, false, p(const Color(0xFFFBBC05)))
      ..drawArc(r, pi * 0.75, -pi * 0.6, false, p(const Color(0xFF34A853)))
      ..drawArc(r, pi * 0.15, -pi * 0.15, false, p(const Color(0xFF4285F4)))
      ..drawLine(
        Offset(size.width * 0.5, size.height * 0.5),
        Offset(size.width * 0.88, size.height * 0.5),
        p(const Color(0xFF4285F4)),
      );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
