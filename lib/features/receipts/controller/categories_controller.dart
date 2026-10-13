import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/models/product_category.dart';
import '../../../core/models/receipt_item.dart';
import '../../../core/models/receipt_model.dart';
import '../../../core/repositories/receipt_repository.dart';

typedef CategoryProduct = ({ReceiptItem item, Receipt receipt});

/// Categories belong to products, so counts are product lines.
List<CategoryProduct> productsIn(ReceiptRepository repo, ProductCategory c) => [
  for (final r in repo.saved)
    for (final item in r.items)
      if (item.category == c) (item: item, receipt: r),
];

/// 13 · Categories
class CategoriesController extends GetxController {
  CategoriesController({required this._receipts});

  final ReceiptRepository _receipts;

  /// Categories that have at least one product, in a stable order.
  List<(ProductCategory, int)> get counts => [
    for (final c in ProductCategory.values)
      if (productsIn(_receipts, c) case final products when products.isNotEmpty)
        (c, products.length),
  ];

  void openCategory(ProductCategory c) =>
      Get.toNamed(Routes.categoryProducts, arguments: c);
}

/// 14 · Category products
class CategoryProductsController extends GetxController {
  CategoryProductsController({required this._receipts, required this.category});

  final ReceiptRepository _receipts;
  final ProductCategory category;

  List<CategoryProduct> get products => productsIn(_receipts, category);

  int get receiptCount => {for (final p in products) p.receipt.id}.length;

  void openReceipt(Receipt r) =>
      Get.toNamed(Routes.receiptDetail, arguments: r.id);
}
