import 'package:get/get.dart';

import '../../../core/models/product_category.dart';
import '../../../core/widgets/route_view.dart';
import '../controller/categories_controller.dart';
import '../controller/receipt_filters_controller.dart';

class ReceiptFiltersBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => ReceiptFiltersController(receipts: Get.find(), list: Get.find()),
    );
  }
}

class CategoriesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => CategoriesController(receipts: Get.find()));
  }
}

class CategoryProductsBinding extends Bindings {
  @override
  void dependencies() {
    final category = Get.arguments as ProductCategory;
    Get.lazyPut(
      () =>
          CategoryProductsController(receipts: Get.find(), category: category),
      tag: currentRouteTag,
    );
  }
}
