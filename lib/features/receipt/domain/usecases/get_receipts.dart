import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/receipt.dart';
import '../repositories/receipt_repository.dart';

class GetReceipts implements UseCase<List<Receipt>, NoParams> {
  const GetReceipts(this._repository);

  final ReceiptRepository _repository;

  @override
  Future<Result<List<Receipt>>> call(NoParams params) =>
      _repository.getReceipts();
}
