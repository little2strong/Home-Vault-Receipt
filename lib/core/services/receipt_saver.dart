import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';

import '../data/paths.dart';
import '../data/vault_repository.dart';
import '../data/vault_store.dart';
import '../models/receipt_draft.dart';
import '../utils/dates.dart';
import 'capture_service.dart';
import 'connectivity_service.dart';
import 'draft_store.dart';
import 'image_tools.dart';

/// Saves a confirmed draft: originals upload once to their final path, then
/// `saveReceipt` writes everything in one batch. Repeat taps and retries
/// reuse the same saveKey, so they never duplicate. Drafts that cannot
/// reach the server wait here and retry when the connection returns.
class ReceiptSaver extends GetxService {
  ReceiptSaver({
    required this.store,
    required this.repo,
    required this.drafts,
    required this.capture,
    required this.connectivity,
  });

  final VaultStore store;
  final VaultRepository repo;
  final DraftStore drafts;
  final CaptureService capture;
  final ConnectivityService connectivity;

  /// Confirmed drafts not yet saved on the server.
  final pending = <ReceiptDraft>[].obs;

  /// Bumped when a draft is kept or thrown away, so Home can refresh its
  /// "Carry on" card.
  final draftsChanged = 0.obs;
  final _inFlight = <String, Future<SaveResult>>{};
  Worker? _onlineWorker;
  Worker? _userWorker;

  @override
  void onInit() {
    super.onInit();
    _userWorker = ever(store.user, (_) => refreshPending());
    _onlineWorker = ever<bool>(connectivity.online, (online) {
      if (online) retryPending();
    });
    refreshPending();
  }

  Future<void> refreshPending() async {
    final uid = store.uid;
    if (uid == null) {
      pending.clear();
      return;
    }
    final all = await drafts.all(uid);
    pending.assignAll(all.where((d) => d.state != DraftState.editing));
    if (connectivity.online.value) unawaited(retryPending());
  }

  /// Unsaved drafts the user was still reviewing, to offer "Carry on".
  Future<List<ReceiptDraft>> unfinished() async {
    final uid = store.uid;
    if (uid == null) return [];
    return (await drafts.all(
      uid,
    )).where((d) => d.state == DraftState.editing).toList();
  }

  Future<void> keep(ReceiptDraft draft) async {
    final uid = store.uid;
    if (uid != null) await drafts.save(uid, draft);
    draftsChanged.value++;
  }

  Future<void> discard(ReceiptDraft draft) async {
    final uid = store.uid;
    if (uid != null) await drafts.remove(uid, draft.id);
    await capture.deleteDraftFiles(draft.id);
    pending.removeWhere((d) => d.id == draft.id);
    draftsChanged.value++;
  }

  Future<void> retryPending() async {
    for (final d in [...pending]) {
      try {
        await save(d);
      } catch (_) {
        // Stays pending; shown on the Pending card.
      }
    }
  }

  /// Returns once the server has confirmed. Throws [ConnectionFailure] when
  /// offline (the draft is then kept as "Waiting for connection").
  Future<SaveResult> save(ReceiptDraft draft) =>
      _inFlight[draft.id] ??= _save(draft).whenComplete(() {
        // A block body: returning the removed Future (this one) from the
        // callback would make whenComplete wait on itself forever.
        _inFlight.remove(draft.id);
      });

  Future<SaveResult> _save(ReceiptDraft draft) async {
    final uid = store.uid;
    if (uid == null) throw const VaultFailure('You are signed out.');
    draft.state = DraftState.waiting;
    draft.lastError = null;
    await drafts.save(uid, draft);

    try {
      if (!connectivity.online.value) throw const ConnectionFailure();
      final originals = await _uploadOriginals(uid, draft);
      final result = await repo.saveReceipt(_payload(draft, originals));
      if (draft.returnDeadline != null) {
        await repo.setReturnDeadline(
          receiptId: result.receiptId,
          deadline: draft.returnDeadline!,
          shop: draft.shop,
          label: draft.items.isEmpty ? null : draft.items.first.name,
          sourceText: draft.returnFromWording ? draft.returnWording : null,
        );
      }
      await _saveWarranties(draft, result);
      await drafts.remove(uid, draft.id);
      await capture.deleteDraftFiles(draft.id);
      pending.removeWhere((d) => d.id == draft.id);
      draftsChanged.value++;
      return result;
    } on ConnectionFailure {
      await _markPending(uid, draft, DraftState.waiting, null);
      rethrow;
    } on FirebaseException catch (e) {
      final offline =
          e.code == 'unavailable' ||
          e.code == 'retry-limit-exceeded' ||
          e.code == 'unknown';
      await _markPending(
        uid,
        draft,
        offline ? DraftState.waiting : DraftState.failed,
        e.message,
      );
      if (offline) throw const ConnectionFailure();
      throw VaultFailure(e.message ?? 'The upload did not finish.');
    } on SocketException {
      await _markPending(uid, draft, DraftState.waiting, null);
      throw const ConnectionFailure();
    } on VaultFailure catch (e) {
      await _markPending(uid, draft, DraftState.failed, e.message);
      rethrow;
    }
  }

  Future<void> _markPending(
    String uid,
    ReceiptDraft draft,
    DraftState state,
    String? error,
  ) async {
    draft.state = state;
    draft.lastError = error;
    await drafts.save(uid, draft);
    final i = pending.indexWhere((d) => d.id == draft.id);
    i >= 0 ? pending[i] = draft : pending.insert(0, draft);
  }

  /// One stored original per receipt. Paths are fixed by the receipt id, so
  /// a retry overwrites instead of adding copies. A page whose file is gone
  /// from the phone (and never uploaded) is left out: listing it would make
  /// `saveReceipt` wait forever for an upload that can't happen.
  Future<List<({String path, String type})>> _uploadOriginals(
    String uid,
    ReceiptDraft draft,
  ) async {
    final originals = <({String path, String type})>[];
    for (var n = 0; n < draft.pages.length; n++) {
      final page = draft.pages[n];
      final path = Paths.original(uid, draft.id, n + 1, page.extension);
      if (draft.uploadedPaths.contains(path)) {
        originals.add((path: path, type: page.contentType));
        continue;
      }
      final file = File(page.localPath);
      if (!file.existsSync()) continue;
      originals.add((path: path, type: page.contentType));
      var bytes = await file.readAsBytes();
      if (!page.isPdf) bytes = await ImageTools.stripGps(bytes);
      await repo.files.put(
        path,
        bytes,
        contentType: page.contentType,
        metadata: {'sha256': ImageTools.sha256Of(bytes)},
      );
      draft.uploadedPaths.add(path);
      await drafts.save(uid, draft);
    }
    return originals;
  }

  Map<String, dynamic> _payload(
    ReceiptDraft d,
    List<({String path, String type})> originals,
  ) => {
    'saveKey': d.saveKey,
    'receiptId': d.id,
    'receipt': {
      'shop': d.shop?.trim().isEmpty ?? true ? null : d.shop!.trim(),
      'purchaseDate': d.purchaseDate == null
          ? null
          : Dates.toIso(d.purchaseDate!),
      'currency': d.currency,
      'totalMinor': d.totalMinor,
      'taxMinor': d.taxMinor,
      'orderNumber': d.orderNumber?.trim().isEmpty ?? true
          ? null
          : d.orderNumber!.trim(),
      'source': d.source.name,
      'originalPaths': [for (final o in originals) o.path],
      'originalTypes': [for (final o in originals) o.type],
      'checksum': d.checksum,
      'ocrText': d.ocrText,
      'returnWording': d.returnWording,
      'extracted': d.extracted,
    },
    'items': [for (final i in d.items) i.toSavePayload()],
  };

  Future<void> _saveWarranties(ReceiptDraft d, SaveResult result) async {
    for (var i = 0; i < d.items.length && i < result.itemIds.length; i++) {
      final item = d.items[i];
      if (item.warrantyEnd == null) continue;
      await repo.saveWarranty(
        itemId: result.itemIds[i],
        endDate: item.warrantyEnd!,
        lengthMonths: item.warrantyMonths,
        itemName: item.name,
        shop: d.shop,
        purchaseDate: d.purchaseDate,
      );
    }
  }

  @override
  void onClose() {
    _onlineWorker?.dispose();
    _userWorker?.dispose();
    super.onClose();
  }
}
