import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/models/ownership_models.dart';
import '../../../core/repositories/ownership_repository.dart';
import '../../../core/utils/dates.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/toast.dart';
import '../../../core/widgets/pickers.dart';

/// One possession's life: 81 · Timeline, 91 · Resale draft,
/// 92 · Ownership status, 95 · Secure sharing.
class LifecycleController extends GetxController {
  LifecycleController({required this._ownership, required this.possessionId});

  static const shareOptions = [
    'Receipt and serial number',
    'Receipt only',
    'Receipt, serial and photos',
  ];
  static const expiryOptions = [
    ('24 hours', Duration(hours: 24)),
    ('7 days', Duration(days: 7)),
    ('30 days', Duration(days: 30)),
  ];

  final OwnershipRepository _ownership;
  final String possessionId;

  // 91 · resale
  final resaleTitle = TextEditingController();
  final accessories = TextEditingController();
  final resalePrice = TextEditingController();
  final resaleDescription = TextEditingController();

  // 92 · status
  final status = OwnershipStatus.owned.obs;
  final saleDate = Rxn<DateTime>();
  final salePrice = TextEditingController();
  final buyerNote = TextEditingController();

  // 95 · sharing
  final shareInclude = shareOptions.first.obs;
  final shareExpiry = 1.obs;

  Possession? get possession => _ownership.byId(possessionId);

  @override
  void onInit() {
    super.onInit();
    final p = possession;
    if (p == null) return;
    resaleTitle.text = [p.brandModel, p.name].whereType<String>().join(' ');
    resaleDescription.text = p.purchaseDate == null
        ? 'Light use.'
        : 'Purchased ${Formatters.months[p.purchaseDate!.month - 1]} '
              '${p.purchaseDate!.year}. Light use.';
    status.value = p.status;
    saleDate.value = p.saleDate;
    if (p.salePrice != null) salePrice.text = Money.toInput(p.salePrice!);
    buyerNote.text = p.buyerNote ?? '';
  }

  String? _statusDetail(Possession p) {
    final parts = <String>[
      if (p.salePrice != null) 'For ${Formatters.currency(p.salePrice!)}.',
      if ((p.buyerNote ?? '').trim().isNotEmpty) p.buyerNote!.trim(),
    ];
    return parts.isEmpty ? null : parts.join(' ');
  }

  /// Purchase, documentation, repairs and status changes, oldest first.
  List<OwnershipEvent> get timeline {
    final p = possession;
    if (p == null) return const [];
    final repairs = _ownership.repairs.where((r) => r.item == p.name);
    return [
      if (p.purchaseDate != null)
        OwnershipEvent(
          label: Formatters.shortDate(p.purchaseDate!),
          title: 'Purchased',
          detail: p.hasReceipt
              ? '${p.retailer ?? 'Store'} receipt attached.'
              : null,
        ),
      ...p.events.where((e) => e.title != 'Purchased'),
      for (final r in repairs)
        OwnershipEvent(
          label: Formatters.shortDate(r.date),
          title: 'Repaired',
          detail: '${r.problem} · ${r.provider}.',
        ),
      if (p.status != OwnershipStatus.owned)
        OwnershipEvent(
          label: p.saleDate == null
              ? 'Status'
              : Formatters.shortDate(p.saleDate!),
          title: p.status.label,
          detail: _statusDetail(p),
        ),
    ];
  }

  void saveListingDraft() {
    final p = possession;
    if (p == null) return;
    if (Money.parse(resalePrice.text) == null) {
      Toast.show('Enter the price you want to ask');
      return;
    }
    _ownership.updatePossession(
      p.copyWith(
        events: [
          ...p.events,
          OwnershipEvent(
            label: 'Today',
            title: 'Listing drafted',
            detail: 'Asking ${Money.format(Money.parse(resalePrice.text)!)}.',
          ),
        ],
      ),
    );
    Get.back();
    Toast.show('Listing draft saved. Nothing is published.');
  }

  Future<void> pickStatus(BuildContext context) async {
    final i = await showOptionSheet(
      context,
      title: 'Status',
      options: [for (final s in OwnershipStatus.values) s.label],
      selected: status.value.index,
    );
    if (i != null) status.value = OwnershipStatus.values[i];
  }

  Future<void> pickSaleDate(BuildContext context) async {
    final picked = await pickDate(
      context,
      initial: saleDate.value ?? _ownership.today,
      last: _ownership.today,
    );
    if (picked != null) saleDate.value = picked;
  }

  void saveStatus() {
    final p = possession;
    if (p == null) return;
    final next = status.value;
    final leaving = next != OwnershipStatus.owned;
    final sold = next == OwnershipStatus.sold;
    final price = Money.parse(salePrice.text);
    final when = saleDate.value;
    if (leaving && when == null) {
      Toast.show(sold ? 'Add the sale date' : 'Add the date');
      return;
    }
    final note = buyerNote.text.trim();
    // Archive the previous status before overwriting it, so a later change
    // (sold, then gifted, then back home) does not erase the earlier one.
    final events = [...p.events];
    if (p.status != next && p.status != OwnershipStatus.owned) {
      events.add(
        OwnershipEvent(
          label: p.saleDate == null
              ? 'Status'
              : Formatters.shortDate(p.saleDate!),
          title: p.status.label,
          detail: _statusDetail(p),
        ),
      );
    }
    _ownership.updatePossession(
      p.copyWith(
        status: next,
        events: events,
        saleDate: leaving ? Dates.dateOnly(when!) : null,
        clearSaleDate: !leaving,
        salePrice: sold ? price : null,
        clearSalePrice: !sold || price == null,
        buyerNote: sold && note.isNotEmpty ? note : null,
        clearBuyerNote: !sold || note.isEmpty,
      ),
    );
    Get.back();
    Toast.show('Ownership updated. The history is kept.');
  }

  Future<void> pickShareInclude(BuildContext context) async {
    final i = await showOptionSheet(
      context,
      title: 'Include',
      options: shareOptions,
      selected: shareOptions.indexOf(shareInclude.value),
    );
    if (i != null) shareInclude.value = shareOptions[i];
  }

  Future<void> pickShareExpiry(BuildContext context) async {
    final i = await showOptionSheet(
      context,
      title: 'Access expiry',
      options: [for (final (label, _) in expiryOptions) label],
      selected: shareExpiry.value,
    );
    if (i != null) shareExpiry.value = i;
  }

  void createLink() {
    final p = possession;
    if (p == null) return;
    final expires = DateTime.now().add(expiryOptions[shareExpiry.value].$2);
    _ownership.shareLinks.add(
      ShareLink(
        record: p.name,
        include: shareInclude.value,
        expiresAt: expires,
      ),
    );
    Get.back();
    Toast.show('Preview only: private links are not live yet.');
  }

  @override
  void onClose() {
    for (final c in [
      resaleTitle,
      accessories,
      resalePrice,
      resaleDescription,
      salePrice,
      buyerNote,
    ]) {
      c.dispose();
    }
    super.onClose();
  }
}
