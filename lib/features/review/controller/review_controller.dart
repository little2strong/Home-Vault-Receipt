import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/models/receipt_extraction.dart';
import '../../../core/models/receipt_item.dart';
import '../../../core/models/receipt_model.dart';
import '../../../core/repositories/receipt_repository.dart';
import '../../../core/utils/dates.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/receipt_date_parser.dart';
import '../../../core/utils/toast.dart';
import '../../../core/widgets/pickers.dart';
import '../../shell/controller/shell_controller.dart';
import 'edit_item_controller.dart';

/// Review of one draft: 23 summary, 24 products, 25 date, 28 duplicate.
///
/// Every change is written straight to the draft record, so leaving the
/// flow never loses work; the draft shows up under "drafts to review".
class ReviewController extends GetxController {
  ReviewController({required this._receipts, required this.receiptId});

  final ReceiptRepository _receipts;
  final String receiptId;

  final formKey = GlobalKey<FormState>();
  final retailerController = TextEditingController();
  final totalController = TextEditingController();

  /// Uncertain OCR fields the user has looked at in this session.
  final confirmed = <ReviewField>{}.obs;
  final selectedItemIds = <String>{}.obs;
  final dateOrder = DateOrder.dayFirst.obs;
  final pendingDate = Rxn<DateTime>();
  final isBusy = false.obs;

  Receipt? get draft => _receipts.byId(receiptId);

  ReceiptExtraction? get extraction => draft?.extraction;

  DateTime get today => _receipts.today;

  @override
  void onInit() {
    super.onInit();
    final d = draft;
    if (d == null) return;
    retailerController.text = d.retailer;
    totalController.text = d.total > 0 ? Money.toInput(d.total) : '';
    selectedItemIds.addAll(d.items.map((i) => i.id));
    pendingDate.value = d.purchaseDate;
  }

  Set<ReviewField> get outstanding =>
      (extraction?.uncertainFields ?? const <ReviewField>{}).difference(
        confirmed,
      );

  bool get needsReview => outstanding.isNotEmpty;

  // 23 · Review summary ------------------------------------------------------

  String get purchaseDateLabel => Formatters.date(draft!.purchaseDate);

  String? get purchaseDateWarning =>
      outstanding.contains(ReviewField.purchaseDate)
      ? AppStrings.checkSource
      : null;

  String get returnDateLabel {
    final d = draft!;
    if (d.returnDeadline != null) {
      return '${Formatters.date(d.returnDeadline!)} · confirmed';
    }
    return extraction?.returnWording != null
        ? 'Stated on receipt · tap to confirm'
        : 'Not stated · leave blank';
  }

  String? get returnDateWarning => outstanding.contains(ReviewField.returnDate)
      ? AppStrings.checkSource
      : null;

  Future<void> openDate() async {
    pendingDate.value = draft?.purchaseDate;
    await Get.toNamed(Routes.editDate, arguments: receiptId);
  }

  Future<void> openReturnTerms() async {
    final acted = await Get.toNamed(Routes.returnTerms, arguments: receiptId);
    if (acted == true) confirmed.add(ReviewField.returnDate);
  }

  Future<void> continueToProducts() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    await _receipts.upsert(
      draft!.copyWith(
        retailer: retailerController.text.trim(),
        total: Money.parse(totalController.text),
      ),
    );
    confirmed.addAll({ReviewField.retailer, ReviewField.total});
    Get.toNamed(Routes.reviewItems, arguments: receiptId);
  }

  Future<void> discardDraft(BuildContext context) async {
    final ok = await confirmDialog(
      context,
      title: 'Discard this draft?',
      message: 'The draft and its original will be removed from this device.',
      confirm: 'Discard',
      destructive: true,
    );
    if (!ok) return;
    await _receipts.delete(receiptId);
    ShellController.openTab(ShellTab.home);
    Toast.show('Draft discarded');
  }

  // 25 · Edit extracted date -------------------------------------------------

  String get recognisedDate => extraction?.rawDate ?? 'Not recognised';

  bool get dateIsAmbiguous {
    final raw = extraction?.rawDate;
    return raw != null && ReceiptDateParser.parse(raw).ambiguous;
  }

  String? get pendingDateError {
    final date = pendingDate.value;
    if (date == null) return 'Choose the purchase date.';
    if (date.isAfter(today)) return 'A purchase date cannot be in the future.';
    return null;
  }

  void setDateOrder(DateOrder order) {
    dateOrder.value = order;
    final raw = extraction?.rawDate;
    if (raw == null) return;
    final parsed = ReceiptDateParser.parse(raw, order: order).date;
    if (parsed != null) pendingDate.value = parsed;
  }

  Future<void> pickDateOrder(BuildContext context) async {
    final i = await showOptionSheet(
      context,
      title: 'Date interpretation',
      options: [for (final o in DateOrder.values) o.label],
      selected: dateOrder.value.index,
    );
    if (i != null) setDateOrder(DateOrder.values[i]);
  }

  Future<void> pickPurchaseDate(BuildContext context) async {
    final picked = await pickDate(
      context,
      initial: pendingDate.value ?? today,
      last: today,
      help: 'Purchase date',
    );
    if (picked != null) pendingDate.value = picked;
  }

  Future<void> useDate() async {
    if (pendingDateError != null) {
      Toast.show(pendingDateError!);
      return;
    }
    final deadline = draft?.returnDeadline;
    if (deadline != null &&
        Dates.dateOnly(deadline).isBefore(pendingDate.value!)) {
      Toast.show('The purchase date is after the return deadline. Check both.');
      return;
    }
    await _receipts.upsert(draft!.copyWith(purchaseDate: pendingDate.value));
    confirmed.add(ReviewField.purchaseDate);
    Get.back();
  }

  // 24 · Review multiple items ---------------------------------------------

  List<ReceiptItem> get items => draft?.items ?? const [];

  int get selectedTotal => items
      .where((i) => selectedItemIds.contains(i.id))
      .fold(0, (sum, i) => sum + i.lineTotal);

  /// Product lines may legitimately differ from the total (discounts,
  /// delivery), so this is shown as a hint, never a blocker.
  String? get totalsHint {
    final d = draft;
    if (d == null || selectedItemIds.isEmpty || selectedTotal == d.total) {
      return null;
    }
    return 'Selected products add up to '
        '${Money.format(selectedTotal, currency: d.currency)}; the receipt '
        'total is ${Money.format(d.total, currency: d.currency)}.';
  }

  void toggleItem(String id, bool selected) =>
      selected ? selectedItemIds.add(id) : selectedItemIds.remove(id);

  Future<void> editItem([ReceiptItem? item]) async {
    final result = await Get.toNamed(
      Routes.editItem,
      arguments: ItemEditArgs(item: item, currency: draft!.currency),
    );
    if (result is! ItemEditResult) return;

    final list = [...items];
    final index = item == null ? -1 : list.indexWhere((i) => i.id == item.id);
    if (result.removed) {
      if (index != -1) list.removeAt(index);
      selectedItemIds.remove(item?.id);
    } else if (index != -1) {
      list[index] = result.item!;
    } else {
      list.add(result.item!);
      selectedItemIds.add(result.item!.id);
    }
    await _receipts.upsert(draft!.copyWith(items: list));
  }

  Receipt _withSelection(Receipt current) => current.copyWith(
    items: [
      for (final i in current.items)
        if (selectedItemIds.contains(i.id)) i,
    ],
  );

  /// Purchase dates and return deadlines are checked here as well as on the
  /// date screen, because a scan can skip that screen entirely.
  String? _dateConflict(Receipt current) {
    if (Dates.dateOnly(current.purchaseDate).isAfter(today)) {
      return 'A purchase date cannot be in the future.';
    }
    final deadline = current.returnDeadline;
    if (deadline != null &&
        Dates.dateOnly(
          deadline,
        ).isBefore(Dates.dateOnly(current.purchaseDate))) {
      return 'The purchase date is after the return deadline. Check both.';
    }
    return null;
  }

  Future<void> confirmAndSave() async {
    if (selectedItemIds.isEmpty) {
      Toast.show('Select at least one product, or add the missing one.');
      return;
    }
    final current = draft;
    if (current == null || isBusy.value) return;
    final dateError = _dateConflict(current);
    if (dateError != null) {
      Toast.show(dateError);
      return;
    }
    final candidate = _withSelection(current);
    // Keep every product until the user leaves this decision. Going back from
    // the duplicate screen must still show the lines they unchecked.
    if (_receipts.findDuplicate(candidate) != null) {
      Get.toNamed(Routes.duplicate, arguments: receiptId);
      return;
    }
    isBusy.value = true;
    try {
      await _receipts.upsert(candidate);
      Get.toNamed(Routes.saving, arguments: receiptId);
    } finally {
      isBusy.value = false;
    }
  }

  // 28 · Duplicate -----------------------------------------------------------

  Receipt? get duplicateOf =>
      draft == null ? null : _receipts.findDuplicate(draft!);

  Future<void> openExisting() async {
    final existing = duplicateOf;
    await _receipts.delete(receiptId);
    ShellController.openTab(ShellTab.receipts);
    if (existing != null) {
      Get.toNamed(Routes.receiptDetail, arguments: existing.id);
    }
    Toast.show('Draft discarded. This receipt is already in your vault.');
  }

  Future<void> saveSeparately() async {
    final current = draft;
    if (current == null || isBusy.value) return;
    isBusy.value = true;
    try {
      await _receipts.upsert(_withSelection(current));
      Get.toNamed(Routes.saving, arguments: receiptId);
    } finally {
      isBusy.value = false;
    }
  }

  @override
  void onClose() {
    retailerController.dispose();
    totalController.dispose();
    super.onClose();
  }
}
