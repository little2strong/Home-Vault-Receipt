import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/models/product_category.dart';
import '../../../core/models/receipt_filter.dart';
import '../../../core/models/receipt_model.dart';
import '../../../core/repositories/receipt_repository.dart';
import '../../../core/utils/formatters.dart';
import '../../capture/capture_launcher.dart';

/// 09 · Receipts, 10 · Search, 11 · Search no results.
class ReceiptsController extends GetxController {
  ReceiptsController({required this._receipts});

  final ReceiptRepository _receipts;

  final searchController = TextEditingController();
  final filter = const ReceiptFilter().obs;

  ReceiptRepository get repository => _receipts;

  int get savedCount => _receipts.savedCount;

  int get pendingCount => _receipts.pending.length;

  List<Receipt> get results => _receipts.search(filter.value);

  /// `All · Electronics · Home` plus any other category in use.
  List<ProductCategory> get quickCategories {
    final used = {for (final r in _receipts.saved) ...r.categories};
    return [
      for (final c in ProductCategory.values)
        if (c == ProductCategory.electronics ||
            c == ProductCategory.home ||
            used.contains(c))
          c,
    ];
  }

  /// Results grouped under month headings, newest month first.
  Map<String, List<Receipt>> get groupedResults {
    final groups = <String, List<Receipt>>{};
    for (final r in results) {
      groups
          .putIfAbsent(Formatters.monthHeader(r.purchaseDate), () => [])
          .add(r);
    }
    return groups;
  }

  void onQueryChanged(String query) =>
      filter.value = filter.value.copyWith(query: query);

  void selectCategory(ProductCategory? category) =>
      filter.value = category == null
      ? filter.value.copyWith(clearCategory: true)
      : filter.value.copyWith(category: category);

  /// Applies refinements from the filter screen, keeping the search text.
  void applyRefinements(ReceiptFilter refined) =>
      filter.value = refined.copyWith(query: filter.value.query);

  void clearAll() {
    searchController.clear();
    filter.value = const ReceiptFilter();
  }

  void openFilters() => Get.toNamed(Routes.receiptFilters);

  void openCategories() => Get.toNamed(Routes.categories);

  void openPending() => Get.toNamed(Routes.pendingUploads);

  void openReceipt(Receipt r) =>
      Get.toNamed(Routes.receiptDetail, arguments: r.id);

  void addReceipt() => CaptureLauncher.start();

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
