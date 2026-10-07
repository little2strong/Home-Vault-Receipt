import '../../domain/entities/receipt.dart';

class ReceiptModel extends Receipt {
  const ReceiptModel({
    required super.id,
    required super.title,
    required super.store,
    required super.amount,
    required super.purchaseDate,
    required super.category,
    super.note,
  });

  factory ReceiptModel.fromEntity(Receipt receipt) => ReceiptModel(
        id: receipt.id,
        title: receipt.title,
        store: receipt.store,
        amount: receipt.amount,
        purchaseDate: receipt.purchaseDate,
        category: receipt.category,
        note: receipt.note,
      );

  factory ReceiptModel.fromJson(Map<String, dynamic> json) => ReceiptModel(
        id: json['id'] as String,
        title: json['title'] as String,
        store: json['store'] as String,
        amount: (json['amount'] as num).toDouble(),
        purchaseDate: DateTime.parse(json['purchase_date'] as String),
        category: ReceiptCategory.values.byName(json['category'] as String),
        note: json['note'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'store': store,
        'amount': amount,
        'purchase_date': purchaseDate.toIso8601String(),
        'category': category.name,
        'note': note,
      };
}
