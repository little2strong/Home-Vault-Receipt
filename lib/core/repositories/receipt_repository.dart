import '../error/app_exception.dart';
import '../models/receipt_model.dart';

/// In-memory store. Swap the internals for Dio/Hive/SQLite without touching
/// controllers or views.
class ReceiptRepository {
  ReceiptRepository({List<Receipt>? seed}) : _receipts = seed ?? _defaultSeed();

  static const _latency = Duration(milliseconds: 300);

  final List<Receipt> _receipts;

  Future<List<Receipt>> getReceipts() async {
    await Future.delayed(_latency);
    return List.unmodifiable(
      [..._receipts]..sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate)),
    );
  }

  Future<Receipt> addReceipt(Receipt receipt) async {
    await Future.delayed(_latency);
    if (_receipts.any((r) => r.id == receipt.id)) {
      throw const AppException('Receipt already exists');
    }
    _receipts.add(receipt);
    return receipt;
  }

  Future<void> deleteReceipt(String id) async {
    await Future.delayed(_latency);
    final index = _receipts.indexWhere((r) => r.id == id);
    if (index == -1) throw const AppException('Receipt not found');
    _receipts.removeAt(index);
  }

  static List<Receipt> _defaultSeed() {
    final now = DateTime.now();
    return [
      Receipt(
        id: '1',
        title: 'Smart TV 55"',
        store: 'Best Electronics',
        amount: 649.99,
        purchaseDate: now.subtract(const Duration(days: 3)),
        category: ReceiptCategory.electronics,
        note: '2-year warranty',
      ),
      Receipt(
        id: '2',
        title: 'Washing Machine',
        store: 'Home Appliance Hub',
        amount: 499.00,
        purchaseDate: now.subtract(const Duration(days: 20)),
        category: ReceiptCategory.appliances,
      ),
      Receipt(
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
