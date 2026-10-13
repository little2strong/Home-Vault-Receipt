import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/models/ownership_models.dart';
import '../../../core/models/receipt_model.dart';
import '../../../core/repositories/ownership_repository.dart';
import '../../../core/repositories/receipt_repository.dart';
import '../../../core/utils/dates.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/toast.dart';
import '../../../core/widgets/pickers.dart';

enum DocumentType {
  warranty('Warranty certificate'),
  manual('Product manual'),
  repair('Repair invoice'),
  insurance('Insurance schedule');

  const DocumentType(this.label);

  final String label;
}

/// 57 · Possession detail, 58 · Gallery, 59 · Documents,
/// 60 · Document extraction.
class PossessionDetailController extends GetxController {
  PossessionDetailController({
    required this._ownership,
    required this._receipts,
    required this.possessionId,
  });

  final OwnershipRepository _ownership;
  final ReceiptRepository _receipts;
  final String possessionId;

  // 60 · extraction form state
  final docType = DocumentType.warranty.obs;
  final warrantyYears = 1.obs;
  final expiry = Rxn<DateTime>();

  Possession? get possession => _ownership.byId(possessionId);

  Receipt? get receipt {
    final id = possession?.receiptId;
    return id == null ? null : _receipts.byId(id);
  }

  String get purchaseLine {
    final p = possession;
    if (p == null) return '';
    final parts = [
      ?p.retailer,
      if (p.purchaseDate != null) Formatters.shortDate(p.purchaseDate!),
      if (p.purchasePrice != null) Formatters.currency(p.purchasePrice!),
    ];
    return parts.isEmpty ? 'No purchase record yet' : parts.join(' · ');
  }

  void openReceipt() {
    final r = receipt;
    if (r == null) {
      Toast.show('No receipt linked yet');
      return;
    }
    Get.toNamed(Routes.receiptDetail, arguments: r.id);
  }

  void open(String route) => Get.toNamed(route, arguments: possessionId);

  void addPhoto() {
    final p = possession;
    if (p == null) return;
    _ownership.updatePossession(
      p.copyWith(photos: [...p.photos, 'Photo ${p.photos.length + 1}']),
    );
  }

  void startExtraction() {
    final p = possession;
    docType.value = DocumentType.warranty;
    warrantyYears.value = 1;
    expiry.value = p?.purchaseDate == null
        ? null
        : Dates.addMonths(p!.purchaseDate!, 12);
    Get.toNamed(Routes.documentExtraction, arguments: possessionId);
  }

  Future<void> pickType(BuildContext context) async {
    final i = await showOptionSheet(
      context,
      title: 'Document type',
      options: [for (final t in DocumentType.values) t.label],
      selected: docType.value.index,
    );
    if (i != null) docType.value = DocumentType.values[i];
  }

  Future<void> pickWarrantyLength(BuildContext context) async {
    final i = await showOptionSheet(
      context,
      title: 'Warranty length',
      options: const ['1 year', '2 years', '3 years', '5 years'],
      selected: const [1, 2, 3, 5].indexOf(warrantyYears.value),
    );
    if (i == null) return;
    warrantyYears.value = const [1, 2, 3, 5][i];
    final bought = possession?.purchaseDate;
    if (bought != null) {
      expiry.value = Dates.addMonths(bought, 12 * warrantyYears.value);
    }
  }

  Future<void> pickExpiry(BuildContext context) async {
    final picked = await pickDate(
      context,
      initial: expiry.value ?? _ownership.today,
      help: 'Expiry',
    );
    if (picked != null) expiry.value = picked;
  }

  void applyDetails() {
    final p = possession;
    if (p == null) return;
    final isWarranty = docType.value == DocumentType.warranty;
    if (isWarranty && expiry.value == null) {
      Toast.show('Confirm the expiry date first.');
      return;
    }
    _ownership.updatePossession(
      p.copyWith(
        documents: [
          ...p.documents,
          OwnedDocument(
            docType.value.label,
            isWarranty
                ? 'Expires ${Formatters.date(expiry.value!)}'
                : 'Added ${Formatters.shortDate(_ownership.today)}',
          ),
        ],
        warrantyExpiry: isWarranty ? expiry.value : null,
      ),
    );
    Get.back();
    Toast.show('Details applied');
  }
}
