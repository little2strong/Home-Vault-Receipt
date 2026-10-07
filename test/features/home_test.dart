import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:home_vault_receipt/core/error/app_exception.dart';
import 'package:home_vault_receipt/core/models/receipt_model.dart';
import 'package:home_vault_receipt/core/repositories/receipt_repository.dart';
import 'package:home_vault_receipt/features/home/controller/home_controller.dart';

Receipt _receipt(String id, String title, ReceiptCategory category) => Receipt(
      id: id,
      title: title,
      store: 'Store $id',
      amount: 10,
      purchaseDate: DateTime(2026, 1, int.parse(id)),
      category: category,
    );

void main() {
  late ReceiptRepository repository;

  setUp(() {
    repository = ReceiptRepository(
      seed: [
        _receipt('1', 'Laptop', ReceiptCategory.electronics),
        _receipt('2', 'Sofa', ReceiptCategory.furniture),
      ],
    );
  });

  group('ReceiptRepository', () {
    test('returns receipts newest first', () async {
      final receipts = await repository.getReceipts();

      expect(receipts.map((r) => r.id), ['2', '1']);
    });

    test('throws AppException when deleting a missing receipt', () {
      expect(
        repository.deleteReceipt('missing'),
        throwsA(isA<AppException>()),
      );
    });
  });

  group('HomeController', () {
    late HomeController controller;

    setUp(() async {
      Get.testMode = true;
      controller = HomeController(repository: repository);
      await controller.fetchReceipts();
    });

    test('filters by category and search query', () {
      expect(controller.filteredReceipts, hasLength(2));

      controller.selectCategory(ReceiptCategory.furniture);
      expect(controller.filteredReceipts.single.title, 'Sofa');

      controller.selectCategory(null);
      controller.onSearchChanged('lap');
      expect(controller.filteredReceipts.single.title, 'Laptop');
    });

    test('totals the filtered receipts', () {
      expect(controller.totalAmount, 20);

      controller.selectCategory(ReceiptCategory.electronics);
      expect(controller.totalAmount, 10);
    });
  });
}
