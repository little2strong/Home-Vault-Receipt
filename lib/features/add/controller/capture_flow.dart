import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/data/vault_repository.dart';
import '../../../core/data/vault_store.dart';
import '../../../core/models/enums.dart';
import '../../../core/models/receipt.dart';
import '../../../core/models/receipt_draft.dart';
import '../../../core/parsing/receipt_parser.dart';
import '../../../core/services/capture_service.dart';
import '../../../core/services/receipt_saver.dart';
import '../../../core/services/text_recognition_service.dart';
import '../../../core/widgets/feedback.dart';

/// What happened to the last save, for the Saved page (16).
class SaveOutcome {
  const SaveOutcome({this.result, this.waiting = false});

  final SaveResult? result;

  /// Offline: kept on the phone and saved automatically later.
  final bool waiting;
}

/// Holds one receipt from capture to save (pages 08–17). Lives while the
/// flow is open and persists the draft after every step.
class CaptureFlow extends GetxController {
  CaptureFlow(this.draft);

  static CaptureFlow get to => Get.find<CaptureFlow>();
  static bool get active => Get.isRegistered<CaptureFlow>();

  final ReceiptDraft draft;

  /// Bumped after each change so `Obx` views rebuild.
  final version = 0.obs;
  final busy = false.obs;
  final readingStep = 0.obs;
  SaveOutcome? outcome;

  VaultStore get store => Get.find();
  VaultRepository get repo => Get.find();
  ReceiptSaver get saver => Get.find();
  CaptureService get capture => Get.find();

  /// Starts a new flow, replacing any unfinished one in memory.
  static CaptureFlow begin(ReceiptSource source) {
    if (active) Get.delete<CaptureFlow>(force: true);
    final repo = Get.find<VaultRepository>();
    final main = Get.find<VaultStore>().profile.value?.mainCurrency ?? 'GBP';
    final draft = ReceiptDraft(
      id: repo.newId('receipts'),
      saveKey: const Uuid().v4(),
      source: source,
      createdAt: DateTime.now(),
      currency: main,
    );
    return Get.put(CaptureFlow(draft), permanent: true);
  }

  /// Re-opens a draft kept on the phone.
  static CaptureFlow resume(ReceiptDraft draft) {
    if (active) Get.delete<CaptureFlow>(force: true);
    return Get.put(CaptureFlow(draft), permanent: true);
  }

  void touch() {
    version.value++;
    unawaited(saver.keep(draft));
  }

  // ------------------------------------------------------------ sources

  Future<void> fromScanner() async {
    try {
      final pages = await capture.scanDocument(draft.id);
      if (pages.isEmpty) return _endIfEmpty();
      draft.pages.addAll(pages);
      touch();
      await Get.toNamed(Routes.pages);
    } catch (e) {
      // No Play services scanner: use the in-app camera instead.
      debugPrint('Scanner unavailable: ${e.runtimeType}');
      await Get.toNamed(Routes.camera);
    }
  }

  Future<void> fromPhotos() async {
    try {
      final pages = await capture.pickPhotos(draft.id);
      if (pages.isEmpty) return _endIfEmpty();
      draft.pages.addAll(pages);
      touch();
      await Get.toNamed(Routes.pages);
    } catch (e) {
      Toast.show(
        "We couldn't open your photos. Check Home Vault can use them.",
      );
      _endIfEmpty();
    }
  }

  Future<void> fromPdf() async {
    try {
      final page = await capture.pickPdf(draft.id);
      if (page == null) return _endIfEmpty();
      draft.pages
        ..clear()
        ..add(page);
      touch();
      await Get.toNamed(Routes.reading);
    } on CaptureProblem catch (e) {
      Toast.show(e.message);
      _endIfEmpty();
    }
  }

  void _endIfEmpty() {
    if (draft.pages.isEmpty && draft.items.isEmpty) end();
  }

  // ------------------------------------------------------------ reading

  /// Page 11: text recognition on the phone, then the parser proposes.
  Future<bool> read() async {
    readingStep.value = 0;
    try {
      draft.checksum = await capture.checksum(draft.pages);
      final ocr = await Get.find<TextRecognitionService>().recognise(
        draft.pages,
      );
      readingStep.value = 1;
      draft.ocrText = ocr.text;
      final parsed = ReceiptParser().parse(ocr);
      await Future<void>.delayed(const Duration(milliseconds: 350));
      readingStep.value = 2;
      apply(parsed);
      await Future<void>.delayed(const Duration(milliseconds: 350));
      readingStep.value = 3;
      return !ocr.isEmpty;
    } catch (e) {
      debugPrint('Reading failed: ${e.runtimeType}');
      return false;
    }
  }

  /// Fills empty fields from the parser. Values the user already
  /// confirmed are never overwritten by a re-scan.
  void apply(ParsedReceipt p) {
    draft.extracted
      ..clear()
      ..addAll(p.toExtractedMap());
    draft.shop ??= p.shop;
    draft.purchaseDate ??= p.purchaseDate;
    if (p.currency != null && draft.totalMinor == null) {
      draft.currency = p.currency!;
    }
    draft.totalMinor ??= p.totalMinor;
    draft.taxMinor ??= p.taxMinor;
    draft.orderNumber ??= p.orderNumber;
    draft.returnWording ??= p.returnWording;
    if (draft.items.isEmpty) {
      var n = 0;
      draft.items = [
        for (final i in p.items)
          DraftItem(
            id: 'i${n++}',
            name: i.name,
            category: i.category,
            quantity: i.quantity,
            unitPriceMinor: i.unitPriceMinor,
            lineTotalMinor: i.lineTotalMinor,
            lineBox: i.box,
            extracted: {
              'name': i.rawText,
              'quantity': i.quantity,
              'unitPriceMinor': i.unitPriceMinor,
              'lineTotalMinor': i.lineTotalMinor,
              'category': i.category.name,
            },
          ),
      ];
    }
    touch();
  }

  bool get dateAmbiguous => draft.extracted['dateAmbiguous'] == true;

  /// Follows the confirmed purchase date, so correcting the date moves the
  /// suggestion with it. Handles "within 30 days" and "until 12/11/2026".
  DateTime? get suggestedReturn {
    final wording = draft.returnWording;
    if (wording == null) return null;
    return ReceiptParser.returnDeadlineFrom(wording, draft.purchaseDate);
  }

  // -------------------------------------------------------------- items

  DraftItem newItem() => DraftItem(
    id: 'i${DateTime.now().microsecondsSinceEpoch}',
    name: '',
    purpose: draft.sameForAll ? draft.sharedPurpose : Purpose.home,
    allocations: draft.sameForAll && draft.sharedRoomId != null
        ? {draft.sharedRoomId!: 1}
        : null,
  );

  void replaceItem(DraftItem item) {
    final i = draft.items.indexWhere((x) => x.id == item.id);
    i >= 0 ? draft.items[i] = item : draft.items.add(item);
    touch();
  }

  void removeItem(String id) {
    draft.items.removeWhere((x) => x.id == id);
    touch();
  }

  void setSameForAll(bool on) {
    draft.sameForAll = on;
    draft.applyShared();
    touch();
  }

  void setShared({Purpose? purpose, String? roomId, String? carId}) {
    if (purpose != null) draft.sharedPurpose = purpose;
    if (roomId != null) draft.sharedRoomId = roomId;
    if (carId != null) draft.sharedCarId = carId;
    draft.applyShared();
    touch();
  }

  /// Rooms are set up the first time an item is put in a room.
  Future<bool> ensureRooms() async {
    if (store.rooms.isNotEmpty) return true;
    await Get.toNamed(Routes.homeSetup);
    return store.rooms.isNotEmpty;
  }

  // --------------------------------------------------------------- save

  /// Checks for a duplicate (page 15), then saves. Returns the duplicate
  /// when the user must decide first.
  Future<Receipt?> checkDuplicate() async {
    if (draft.duplicateAcknowledged) return null;
    return repo.findDuplicate(
      checksum: draft.checksum,
      shop: draft.shop,
      purchaseDate: draft.purchaseDate,
      totalMinor: draft.totalMinor,
    );
  }

  Future<void> save() async {
    if (busy.value) return;
    busy.value = true;
    draft.applyShared();
    try {
      final result = await saver.save(draft);
      outcome = SaveOutcome(result: result);
      await Get.offAllNamed(Routes.saved);
    } on ConnectionFailure {
      outcome = const SaveOutcome(waiting: true);
      await Get.offAllNamed(Routes.saved);
    } on VaultFailure catch (e) {
      Toast.show(e.message);
    } catch (e) {
      Toast.show('Saving did not finish. Your draft is kept — try again.');
    } finally {
      busy.value = false;
    }
  }

  /// Throws the draft away after the user confirms.
  Future<void> discard(BuildContext context) async {
    final ok = await Pickers.confirm(
      context,
      title: 'Discard this receipt?',
      message: 'The photos and details you checked will be removed.',
      action: 'Discard',
      destructive: true,
    );
    if (!ok) return;
    await saver.discard(draft);
    end();
    Get.until((r) => r.settings.name == Routes.shell || r.isFirst);
  }

  /// Leaves the flow, keeping the draft on the phone to carry on later.
  void leave() {
    unawaited(saver.keep(draft));
    end();
    Get.until((r) => r.settings.name == Routes.shell || r.isFirst);
  }

  void end() {
    if (active) Get.delete<CaptureFlow>(force: true);
  }
}
