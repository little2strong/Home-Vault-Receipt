import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';
import '../theme/vault_palette.dart';

/// The "YOUR RECEIPT" card with a check badge used on welcome, empty and
/// confirmation screens. Decorative, so hidden from screen readers.
class ReceiptIllustration extends StatelessWidget {
  const ReceiptIllustration({super.key, this.height = 190});

  final double height;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final width = height * 0.75;

    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSizes.md),
        child: Center(
          child: SizedBox(
            width: width + 24,
            height: height + 12,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 12,
                  bottom: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: p.illustration,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  top: 0,
                  bottom: 16,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: p.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Icon(
                            Icons.receipt_long_outlined,
                            color: p.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'YOUR RECEIPT',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            color: p.ink,
                          ),
                        ),
                        const SizedBox(height: 10),
                        for (final f in const [0.85, 0.6, 0.85, 0.55]) ...[
                          FractionallySizedBox(
                            widthFactor: f,
                            child: Container(height: 4, color: p.outline),
                          ),
                          const SizedBox(height: 9),
                        ],
                        const Spacer(),
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: p.primary,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: p.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check_rounded, color: p.onPrimary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
