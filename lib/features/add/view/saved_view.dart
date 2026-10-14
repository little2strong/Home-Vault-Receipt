import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/models/enums.dart';
import '../../../core/models/receipt_draft.dart';
import '../../../core/services/capture_service.dart';
import '../../../core/theme/vault_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/vault_ui.dart';
import '../controller/capture_flow.dart';

class SavedController extends GetxController {
  late final CaptureFlow? _flow = CaptureFlow.active ? CaptureFlow.to : null;
  late final SaveOutcome outcome = _flow?.outcome ?? const SaveOutcome();
  late final ReceiptDraft? draft = _flow?.draft;

  bool get waiting => outcome.waiting;

  /// The first item worth a warranty or a photo, with its saved id.
  ({String id, String name})? get highlight {
    final d = draft;
    final ids = outcome.result?.itemIds ?? const [];
    if (d == null) return null;
    for (var i = 0; i < d.items.length && i < ids.length; i++) {
      final item = d.items[i];
      if (item.isPhysical &&
          const {
            Category.electronics,
            Category.appliances,
            Category.furniture,
            Category.jewellery,
          }.contains(item.category)) {
        return (id: ids[i], name: _short(item.name));
      }
    }
    return null;
  }

  bool get highlightHasWarranty {
    final d = draft;
    if (d == null) return false;
    return d.items.any((i) => i.warrantyEnd != null);
  }

  /// `Samsung 55" QLED TV` → `TV` for "Photograph the TV".
  static String _short(String name) {
    final words = name.split(' ');
    return words.length > 3 ? words.last : name;
  }

  @override
  void onClose() {
    _flow?.end();
    super.onClose();
  }

  void viewReceipt() {
    final id = outcome.result?.receiptId;
    Get.offAllNamed(Routes.shell);
    if (id != null) Get.toNamed(Routes.receipt(id));
  }

  Future<void> scanAnother() async {
    await Get.offAllNamed(Routes.shell);
    final flow = CaptureFlow.begin(ReceiptSource.camera);
    if (Get.find<CaptureService>().hasDocumentScanner) {
      await flow.fromScanner();
    } else {
      await Get.toNamed(Routes.camera);
    }
  }

  void open(String route) {
    Get.offAllNamed(Routes.shell);
    Get.toNamed(route);
  }
}

/// 16 Saved — shown only after the server confirms.
class SavedView extends GetView<SavedController> {
  const SavedView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.textStyles;
    final c = controller;
    final d = c.draft;
    final result = c.outcome.result;
    final h = c.highlight;
    return AppPage(
      showBack: false,
      actions: [
        if (c.waiting)
          VaultButton(
            label: 'Done',
            onPressed: () => Get.offAllNamed(Routes.shell),
          )
        else
          VaultButton(label: 'View receipt', onPressed: c.viewReceipt),
        VaultButton.secondary(label: 'Scan another', onPressed: c.scanAnother),
      ],
      children: [
        const SizedBox(height: 60),
        Center(
          child: CircleAvatar(
            radius: 64,
            backgroundColor: c.waiting ? p.warningSurface : p.primary,
            child: Icon(
              c.waiting ? Icons.cloud_upload_outlined : Icons.check_rounded,
              size: 64,
              color: c.waiting ? p.warningInk : Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Semantics(
          liveRegion: true,
          header: true,
          child: Text(
            c.waiting ? 'Waiting for connection' : 'Saved',
            textAlign: TextAlign.center,
            style: t.displaySmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 10),
        if (c.waiting)
          Text(
            "${d?.shop ?? 'Your receipt'} is kept on this phone. We'll save it "
            "as soon as you're back online — it isn't saved yet.",
            textAlign: TextAlign.center,
            style: t.titleMedium?.copyWith(
              color: p.muted,
              fontWeight: FontWeight.w400,
            ),
          )
        else ...[
          Text.rich(
            TextSpan(
              text: 'Receipt ',
              children: [
                TextSpan(
                  text: result?.number ?? '',
                  style: TextStyle(fontWeight: FontWeight.w800, color: p.ink),
                ),
                TextSpan(
                  text:
                      ' · ${d?.shop ?? 'Shop not stated'} · ${Formatters.count(d?.items.length ?? 0, 'item')}',
                ),
              ],
            ),
            textAlign: TextAlign.center,
            style: t.titleMedium?.copyWith(
              color: p.muted,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 4),
          if (d?.pages.isNotEmpty ?? false)
            Text(
              'Original stored privately. Only you can open it.',
              textAlign: TextAlign.center,
              style: TextStyle(color: p.muted),
            ),
          if (h != null) ...[
            const SectionLabel('Worth doing now'),
            ListCard(
              indent: 70,
              children: [
                if (!c.highlightHasWarranty)
                  RowTile(
                    leading: const IconTile(Icons.shield_outlined),
                    title: "Add the ${h.name}'s warranty",
                    subtitle: 'Get a reminder before it ends',
                    chevron: true,
                    onTap: () => c.open(Routes.warranty(h.id)),
                  ),
                RowTile(
                  leading: const IconTile(Icons.photo_camera_outlined),
                  title: 'Photograph the ${h.name}',
                  subtitle: 'Helpful if you ever need to claim',
                  chevron: true,
                  onTap: () => c.open(Routes.photos(h.id)),
                ),
              ],
            ),
          ],
        ],
      ],
    );
  }
}
