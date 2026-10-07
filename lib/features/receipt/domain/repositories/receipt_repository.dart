import '../../../../core/utils/result.dart';
import '../entities/receipt.dart';

abstract interface class ReceiptRepository {
  Future<Result<List<Receipt>>> getReceipts();

  Future<Result<Receipt>> addReceipt(Receipt receipt);

  Future<Result<void>> deleteReceipt(String id);
}
