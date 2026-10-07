import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/receipt.dart';
import '../../domain/usecases/delete_receipt.dart';
import '../../domain/usecases/get_receipts.dart';

class ReceiptController extends GetxController {
  ReceiptController({
    required this._getReceipts,
    required this._deleteReceipt,
  });

  final GetReceipts _getReceipts;
  final DeleteReceipt _deleteReceipt;

  final receipts = <Receipt>[].obs;
  final isLoading = false.obs;
  final errorMessage = RxnString();
  final searchQuery = ''.obs;
  final selectedCategory = Rxn<ReceiptCategory>();

  List<Receipt> get filteredReceipts {
    final query = searchQuery.value.trim().toLowerCase();
    final category = selectedCategory.value;

    return receipts.where((r) {
      final matchesCategory = category == null || r.category == category;
      final matchesQuery = query.isEmpty ||
          r.title.toLowerCase().contains(query) ||
          r.store.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  double get totalAmount =>
      filteredReceipts.fold(0, (sum, r) => sum + r.amount);

  bool get hasActiveFilter =>
      searchQuery.value.isNotEmpty || selectedCategory.value != null;

  @override
  void onInit() {
    super.onInit();
    fetchReceipts();
  }

  Future<void> fetchReceipts() async {
    isLoading.value = true;
    errorMessage.value = null;

    final result = await _getReceipts(const NoParams());
    result.when(
      ok: receipts.assignAll,
      err: (failure) => errorMessage.value = failure.message,
    );

    isLoading.value = false;
  }

  Future<void> openAddReceipt() async {
    final created = await Get.toNamed(Routes.addReceipt);
    if (created is Receipt) await fetchReceipts();
  }

  Future<void> removeReceipt(Receipt receipt) async {
    final index = receipts.indexOf(receipt);
    receipts.remove(receipt);

    final result = await _deleteReceipt(receipt.id);
    result.when(
      ok: (_) => Get.snackbar(AppStrings.success, AppStrings.receiptDeleted),
      err: (failure) {
        receipts.insert(index, receipt);
        Get.snackbar(AppStrings.error, failure.message);
      },
    );
  }

  void onSearchChanged(String query) => searchQuery.value = query;

  void selectCategory(ReceiptCategory? category) =>
      selectedCategory.value = category;
}
