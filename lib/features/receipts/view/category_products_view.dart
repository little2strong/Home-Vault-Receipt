import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/route_view.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/categories_controller.dart';

/// 14 · Category products
class CategoryProductsView extends RouteView<CategoryProductsController> {
  const CategoryProductsView({super.key});

  @override
  Widget buildWith(
    BuildContext context,
    CategoryProductsController controller,
  ) {
    return Obx(() {
      final products = controller.products;
      return VaultPage(
        title: controller.category.label,
        subtitle:
            '${Formatters.count(products.length, 'product')} across '
            '${Formatters.count(controller.receiptCount, 'receipt')}.',
        children: [
          for (final p in products)
            InfoCard(
              title: p.item.name,
              subtitle:
                  '${p.receipt.retailer} · '
                  '${Money.format(p.item.lineTotal, currency: p.receipt.currency)}',
              onTap: () => controller.openReceipt(p.receipt),
            ),
        ],
      );
    });
  }
}
