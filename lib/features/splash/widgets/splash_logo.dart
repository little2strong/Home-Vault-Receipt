import 'package:flutter/material.dart';

class SplashLogo extends StatelessWidget {
  const SplashLogo({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: scheme.onPrimary,
        borderRadius: BorderRadius.circular(size / 4),
      ),
      child: Icon(
        Icons.receipt_long_rounded,
        size: size * 0.55,
        color: scheme.primary,
      ),
    );
  }
}
