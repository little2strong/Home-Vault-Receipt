import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/models/receipt_model.dart';
import '../../../core/repositories/receipt_repository.dart';

class HomeController extends GetxController {
  HomeController({required this._repository});

  final ReceiptRepository _repository;

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

    try {
      receipts.assignAll(await _repository.getReceipts());
    } on AppException catch (e) {
      errorMessage.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> openAddReceipt() async {
    final created = await Get.toNamed(Routes.addReceipt);
    if (created is Receipt) await fetchReceipts();
  }

  Future<void> removeReceipt(Receipt receipt) async {
    final index = receipts.indexOf(receipt);
    receipts.remove(receipt);

    try {
      await _repository.deleteReceipt(receipt.id);
      Get.snackbar(AppStrings.success, AppStrings.receiptDeleted);
    } on AppException catch (e) {
      receipts.insert(index, receipt);
      Get.snackbar(AppStrings.error, e.message);
    }
  }

  void onSearchChanged(String query) => searchQuery.value = query;

  void selectCategory(ReceiptCategory? category) =>
      selectedCategory.value = category;
}
