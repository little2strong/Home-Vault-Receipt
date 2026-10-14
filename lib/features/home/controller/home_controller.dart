import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/data/vault_store.dart';
import '../../../core/models/enums.dart';
import '../../../core/models/item.dart';
import '../../../core/models/receipt.dart';
import '../../../core/models/receipt_draft.dart';
import '../../../core/services/receipt_saver.dart';
import '../../add/controller/capture_flow.dart';

/// A row in "Recent purchases": one item, or a whole consumable receipt
/// (`Tesco food shop · 23 items`).
sealed class RecentRow {}

class RecentItem extends RecentRow {
  RecentItem(this.item);
  final Item item;
}

class RecentReceipt extends RecentRow {
  RecentReceipt(this.receipt);
  final Receipt receipt;
}

class HomeController extends GetxController {
  HomeController(this.store, this.saver);

  final VaultStore store;
  final ReceiptSaver saver;
  final unfinished = <ReceiptDraft>[].obs;

  @override
  void onReady() {
    super.onReady();
    refreshDrafts();
    ever(store.user, (_) => refreshDrafts());
  }

  Future<void> refreshDrafts() async =>
      unfinished.assignAll(await saver.unfinished());

  String get greeting {
    final h = DateTime.now().hour;
    return h < 12
        ? 'Good morning,'
        : h < 18
        ? 'Good afternoon,'
        : 'Good evening,';
  }

  /// Newest purchases first; receipts of only consumables collapse to one
  /// row so a food shop doesn't fill the list.
  List<RecentRow> get recent {
    final rows = <RecentRow>[];
    final seenReceipts = <String>{};
    for (final item in store.items) {
      if (rows.length >= 5) break;
      final rid = item.receiptId;
      if (rid != null) {
        if (seenReceipts.contains(rid)) continue;
        final siblings = store.itemsOnReceipt(rid);
        final receipt = store.receipt(rid);
        if (receipt != null &&
            siblings.length > 3 &&
            siblings.every((i) => i.type == ItemType.consumable)) {
          seenReceipts.add(rid);
          rows.add(RecentReceipt(receipt));
          continue;
        }
      }
      rows.add(RecentItem(item));
    }
    return rows;
  }

  void resume(ReceiptDraft draft) {
    CaptureFlow.resume(draft);
    Get.toNamed(
      draft.items.isEmpty && draft.pages.isNotEmpty
          ? Routes.reading
          : Routes.reviewDetails,
    );
  }
}
