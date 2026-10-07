import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/receipt.dart';
import '../../domain/repositories/receipt_repository.dart';
import '../datasources/receipt_local_data_source.dart';
import '../models/receipt_model.dart';

class ReceiptRepositoryImpl implements ReceiptRepository {
  const ReceiptRepositoryImpl(this._localDataSource);

  final ReceiptLocalDataSource _localDataSource;

  @override
  Future<Result<List<Receipt>>> getReceipts() =>
      _guard(_localDataSource.getReceipts);

  @override
  Future<Result<Receipt>> addReceipt(Receipt receipt) =>
      _guard(() => _localDataSource.addReceipt(ReceiptModel.fromEntity(receipt)));

  @override
  Future<Result<void>> deleteReceipt(String id) =>
      _guard(() => _localDataSource.deleteReceipt(id));

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Ok(await action());
    } on CacheException catch (e) {
      return Err(CacheFailure(e.message));
    } catch (_) {
      return const Err(UnexpectedFailure());
    }
  }
}
