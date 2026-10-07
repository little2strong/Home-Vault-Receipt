import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:home_vault_receipt/core/error/failures.dart';
import 'package:home_vault_receipt/core/utils/result.dart';
import 'package:home_vault_receipt/features/receipt/data/datasources/receipt_local_data_source.dart';
import 'package:home_vault_receipt/features/receipt/data/models/receipt_model.dart';
import 'package:home_vault_receipt/features/receipt/data/repositories/receipt_repository_impl.dart';
import 'package:home_vault_receipt/features/receipt/domain/entities/receipt.dart';
import 'package:home_vault_receipt/features/receipt/domain/usecases/delete_receipt.dart';
import 'package:home_vault_receipt/features/receipt/domain/usecases/get_receipts.dart';
import 'package:home_vault_receipt/features/receipt/presentation/controllers/receipt_controller.dart';

ReceiptModel _receipt(String id, String title, ReceiptCategory category) =>
    ReceiptModel(
      id: id,
      title: title,
      store: 'Store $id',
      amount: 10,
      purchaseDate: DateTime(2026, 1, int.parse(id)),
      category: category,
    );

void main() {
  late ReceiptRepositoryImpl repository;

  setUp(() {
    repository = ReceiptRepositoryImpl(
      ReceiptLocalDataSourceImpl(
        seed: [
          _receipt('1', 'Laptop', ReceiptCategory.electronics),
          _receipt('2', 'Sofa', ReceiptCategory.furniture),
        ],
      ),
    );
  });

  group('ReceiptRepositoryImpl', () {
    test('returns receipts newest first', () async {
      final result = await repository.getReceipts();

      expect(result, isA<Ok<List<Receipt>>>());
      final ids = (result as Ok<List<Receipt>>).data.map((r) => r.id);
      expect(ids, ['2', '1']);
    });

    test('maps a missing receipt on delete to CacheFailure', () async {
      final result = await repository.deleteReceipt('missing');

      expect(result, isA<Err<void>>());
      expect((result as Err<void>).failure, isA<CacheFailure>());
    });
  });

  group('ReceiptController', () {
    late ReceiptController controller;

    setUp(() async {
      Get.testMode = true;
      controller = ReceiptController(
        getReceipts: GetReceipts(repository),
        deleteReceipt: DeleteReceipt(repository),
      );
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
