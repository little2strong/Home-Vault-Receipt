import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/categories_controller.dart';

/// 13 · Categories
class CategoriesView extends GetView<CategoriesController> {
  const CategoriesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final counts = controller.counts;
      return VaultPage(
        title: 'A place for\neverything.',
        subtitle: 'Categories belong to individual products.',
        children: [
          if (counts.isEmpty)
            const InfoCard(
              title: 'No products yet',
              subtitle: 'Categories appear once you save a receipt.',
            ),
          for (final (category, count) in counts)
            InfoCard(
              title: category.label,
              subtitle: Formatters.count(count, 'product'),
              onTap: () => controller.openCategory(category),
            ),
        ],
      );
    });
  }
}
