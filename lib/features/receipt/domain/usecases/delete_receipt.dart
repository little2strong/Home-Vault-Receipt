import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../repositories/receipt_repository.dart';

class DeleteReceipt implements UseCase<void, String> {
  const DeleteReceipt(this._repository);

  final ReceiptRepository _repository;

  @override
  Future<Result<void>> call(String id) => _repository.deleteReceipt(id);
}
