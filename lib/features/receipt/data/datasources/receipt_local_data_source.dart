import '../../../../core/error/exceptions.dart';
import '../../domain/entities/receipt.dart';
import '../models/receipt_model.dart';

abstract interface class ReceiptLocalDataSource {
  Future<List<ReceiptModel>> getReceipts();

  Future<ReceiptModel> addReceipt(ReceiptModel receipt);

  Future<void> deleteReceipt(String id);
}

/// In-memory store. Swap for Hive/SQLite/etc. without touching other layers.
class ReceiptLocalDataSourceImpl implements ReceiptLocalDataSource {
  ReceiptLocalDataSourceImpl({List<ReceiptModel>? seed})
      : _receipts = seed ?? _defaultSeed();

  static const _latency = Duration(milliseconds: 300);

  final List<ReceiptModel> _receipts;

  @override
  Future<List<ReceiptModel>> getReceipts() async {
    await Future.delayed(_latency);
    return List.unmodifiable(
      [..._receipts]..sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate)),
    );
  }

  @override
  Future<ReceiptModel> addReceipt(ReceiptModel receipt) async {
    await Future.delayed(_latency);
    if (_receipts.any((r) => r.id == receipt.id)) {
      throw const CacheException('Receipt already exists');
    }
    _receipts.add(receipt);
    return receipt;
  }

  @override
  Future<void> deleteReceipt(String id) async {
    await Future.delayed(_latency);
    final index = _receipts.indexWhere((r) => r.id == id);
    if (index == -1) throw const CacheException('Receipt not found');
    _receipts.removeAt(index);
  }

  static List<ReceiptModel> _defaultSeed() {
    final now = DateTime.now();
    return [
      ReceiptModel(
        id: '1',
        title: 'Smart TV 55"',
        store: 'Best Electronics',
        amount: 649.99,
        purchaseDate: now.subtract(const Duration(days: 3)),
        category: ReceiptCategory.electronics,
        note: '2-year warranty',
      ),
      ReceiptModel(
        id: '2',
        title: 'Washing Machine',
        store: 'Home Appliance Hub',
        amount: 499.00,
        purchaseDate: now.subtract(const Duration(days: 20)),
        category: ReceiptCategory.appliances,
      ),
      ReceiptModel(
        id: '3',
        title: 'Dining Table',
        store: 'Wood & Co.',
        amount: 320.50,
        purchaseDate: now.subtract(const Duration(days: 45)),
        category: ReceiptCategory.furniture,
      ),
    ];
  }
}
