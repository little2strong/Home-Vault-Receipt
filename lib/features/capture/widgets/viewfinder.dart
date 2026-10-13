import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/vault_palette.dart';

/// Camera frame with corner guides around [child].
class Viewfinder extends StatelessWidget {
  const Viewfinder({super.key, required this.child, this.semanticLabel});

  final Widget child;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      label: semanticLabel,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Color.alphaBlend(
            p.primary.withValues(alpha: 0.12),
            p.illustration,
          ),
          borderRadius: BorderRadius.circular(AppSizes.radius),
        ),
        child: CustomPaint(
          foregroundPainter: _CornerPainter(p.primary),
          child: Padding(padding: const EdgeInsets.all(14), child: child),
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  _CornerPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const len = 18.0;
    const inset = -14.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final l = inset, t = inset, r = size.width - inset, b = size.height - inset;
    final path = Path()
      ..moveTo(l, t + len)
      ..lineTo(l, t)
      ..lineTo(l + len, t)
      ..moveTo(r - len, t)
      ..lineTo(r, t)
      ..lineTo(r, t + len)
      ..moveTo(l, b - len)
      ..lineTo(l, b)
      ..lineTo(l + len, b)
      ..moveTo(r - len, b)
      ..lineTo(r, b)
      ..lineTo(r, b - len);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CornerPainter old) => old.color != color;
}
