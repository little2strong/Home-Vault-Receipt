import 'package:flutter/material.dart';

import '../../../core/theme/vault_palette.dart';

class SplashLogo extends StatelessWidget {
  const SplashLogo({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(size / 4),
        ),
        child: Icon(
          Icons.receipt_long_rounded,
          size: size * 0.55,
          color: p.primary,
        ),
      ),
    );
  }
}
