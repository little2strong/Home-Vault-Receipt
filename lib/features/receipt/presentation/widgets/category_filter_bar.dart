import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../domain/entities/receipt.dart';

class CategoryFilterBar extends StatelessWidget {
  const CategoryFilterBar({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final ReceiptCategory? selected;
  final ValueChanged<ReceiptCategory?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
        children: [
          _chip(AppStrings.all, null),
          for (final category in ReceiptCategory.values)
            _chip(category.label, category),
        ],
      ),
    );
  }

  Widget _chip(String label, ReceiptCategory? category) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSizes.sm),
      child: ChoiceChip(
        label: Text(label),
        selected: selected == category,
        onSelected: (_) => onSelected(category),
      ),
    );
  }
}
