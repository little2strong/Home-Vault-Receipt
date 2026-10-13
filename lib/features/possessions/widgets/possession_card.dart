import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/models/ownership_models.dart';
import '../../../core/models/product_category.dart';
import '../../../core/theme/vault_palette.dart';

/// Grid tile: thumbnail, name and `Office · Owned`.
class PossessionCard extends StatelessWidget {
  const PossessionCard({
    super.key,
    required this.possession,
    required this.onTap,
  });

  final Possession possession;
  final VoidCallback onTap;

  static IconData iconFor(ProductCategory c) => switch (c) {
    ProductCategory.electronics => Icons.laptop_mac_rounded,
    ProductCategory.home => Icons.chair_outlined,
    ProductCategory.appliances => Icons.coffee_maker_outlined,
    ProductCategory.groceries => Icons.shopping_basket_outlined,
    ProductCategory.clothing => Icons.watch_outlined,
    ProductCategory.other => Icons.inventory_2_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      label:
          '${possession.name}, ${possession.room}, ${possession.status.label}',
      excludeSemantics: true,
      child: Material(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSizes.radius),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: p.tonal,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      iconFor(possession.category),
                      color: p.primary,
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  possession.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  '${possession.room} · ${possession.status.label}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.bodySmall,
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
