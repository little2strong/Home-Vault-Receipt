import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/receipt.dart';
import '../repositories/receipt_repository.dart';

class AddReceipt implements UseCase<Receipt, Receipt> {
  const AddReceipt(this._repository);

  final ReceiptRepository _repository;

  @override
  Future<Result<Receipt>> call(Receipt receipt) =>
      _repository.addReceipt(receipt);
}
