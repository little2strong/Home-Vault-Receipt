import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/models/product_category.dart';
import '../../../core/widgets/status_chip.dart';

class CategoryPills extends StatelessWidget {
  const CategoryPills({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelected,
    required this.onBrowse,
  });

  final List<ProductCategory> categories;
  final ProductCategory? selected;
  final ValueChanged<ProductCategory?> onSelected;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ChoicePill(
            label: AppStrings.all,
            selected: selected == null,
            onTap: () => onSelected(null),
          ),
          for (final category in categories) ...[
            const SizedBox(width: AppSizes.sm),
            ChoicePill(
              label: category.shortLabel,
              selected: selected == category,
              onTap: () => onSelected(category),
            ),
          ],
          const SizedBox(width: AppSizes.sm),
          TextButton(onPressed: onBrowse, child: const Text('All categories')),
        ],
      ),
    );
  }
}
