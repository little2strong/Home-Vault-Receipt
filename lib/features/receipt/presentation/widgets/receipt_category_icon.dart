import 'package:flutter/material.dart';

import '../../domain/entities/receipt.dart';

class ReceiptCategoryIcon extends StatelessWidget {
  const ReceiptCategoryIcon({super.key, required this.category, this.size = 44});

  final ReceiptCategory category;
  final double size;

  static IconData iconFor(ReceiptCategory category) => switch (category) {
        ReceiptCategory.electronics => Icons.devices_rounded,
        ReceiptCategory.appliances => Icons.kitchen_rounded,
        ReceiptCategory.furniture => Icons.chair_rounded,
        ReceiptCategory.groceries => Icons.shopping_basket_rounded,
        ReceiptCategory.other => Icons.receipt_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(size / 3),
      ),
      child: Icon(
        iconFor(category),
        size: size * 0.5,
        color: scheme.onPrimaryContainer,
      ),
    );
  }
}
