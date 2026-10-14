import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/data/vault_store.dart';
import '../../../core/models/enums.dart';
import '../../../core/models/receipt.dart';
import '../../../core/models/receipt_draft.dart';
import '../../../core/theme/vault_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/vault_ui.dart';
import '../controller/capture_flow.dart';
import 'edit_item_sheet.dart';
import 'review_details_view.dart';

class ReviewItemsController extends GetxController {
  CaptureFlow get flow => CaptureFlow.to;
  ReceiptDraft get d => flow.draft;
  VaultStore get store => flow.store;

  String roomName(String? id) =>
      id == null ? 'No room' : (store.room(id)?.name ?? 'Room');

  Future<void> edit(DraftItem item) async {
    final updated = await EditItemSheet.open(
      item: item,
      currency: d.currency,
      purchaseDate: d.purchaseDate,
      onViewOnReceipt: item.lineBox == null || d.pages.isEmpty
          ? null
          : () => LocalPagesViewer.open(d.pages, box: item.lineBox),
      onDelete: () => flow.removeItem(item.id),
    );
    if (updated == null) return;
    // Changing one item's purpose or room switches "Same for all" off.
    if (d.sameForAll &&
        (updated.purpose != d.sharedPurpose ||
            (updated.isPhysical &&
                updated.inHome &&
                d.sharedRoomId != null &&
                updated.roomId != d.sharedRoomId))) {
      d.sameForAll = false;
    }
    flow.replaceItem(updated);
  }

  Future<void> add() async {
    final created = await EditItemSheet.open(
      item: flow.newItem(),
      currency: d.currency,
      purchaseDate: d.purchaseDate,
    );
    if (created != null) flow.replaceItem(created);
  }

  Future<void> sharedPurpose(BuildContext context) async {
    final p = await Pickers.choose<Purpose>(
      context,
      title: 'Purpose for all items',
      values: Purpose.values,
      label: (v) => v.label,
      selected: d.sharedPurpose,
    );
    if (p == null) return;
    String? carId;
    if (p == Purpose.car && store.cars.length > 1 && context.mounted) {
      carId = await Pickers.choose<String>(
        context,
        title: 'Which car?',
        values: [for (final c in store.cars) c.id],
        label: (id) => store.car(id)!.name,
      );
    } else if (p == Purpose.car && store.cars.length == 1) {
      carId = store.cars.first.id;
    }
    flow.setShared(purpose: p, carId: carId);
  }

  Future<void> sharedRoom(BuildContext context) async {
    if (!await flow.ensureRooms() || !context.mounted) return;
    final id = await Pickers.room(
      context,
      rooms: store.rooms,
      selected: d.sharedRoomId,
      onSetUp: () => Get.toNamed(Routes.homeSetup),
    );
    if (id != null) flow.setShared(roomId: id);
  }

  Future<void> save(BuildContext context) async {
    if (d.items.isEmpty) {
      final ok = await Pickers.confirm(
        context,
        title: 'Save without items?',
        message:
            'The receipt is saved, but nothing is added to your products. '
            'You can add items later.',
        action: 'Save receipt',
      );
      if (!ok) return;
    }
    final dup = await flow.checkDuplicate();
    if (dup != null && context.mounted) {
      final choice = await DuplicateDialog.show(context, saved: dup, draft: d);
      switch (choice) {
        case DuplicateChoice.discard:
          await flow.saver.discard(d);
          flow.end();
          await Get.offAllNamed(Routes.shell);
          return;
        case DuplicateChoice.open:
          flow.leave();
          await Get.toNamed(Routes.receipt(dup.id));
          return;
        case DuplicateChoice.keepBoth:
          d.duplicateAcknowledged = true;
        case null:
          return;
      }
    }
    await flow.save();
  }
}

/// 13 Review step 2: items with Type, Purpose and Room tags; "Same for all".
class ReviewItemsView extends GetView<ReviewItemsController> {
  const ReviewItemsView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.textStyles;
    final d = controller.d;
    return Obx(() {
      controller.flow.version.value;
      controller.store.rooms.length;
      final hasPhysical = d.items.any((i) => i.isPhysical && i.inHome);
      return AppPage(
        titleInHeader: false,
        trailing: Text(
          '${d.shop ?? 'Shop not stated'} · ${d.totalMinor == null ? 'Total not stated' : Money.format(d.totalMinor!, currency: d.currency)}',
          style: t.titleMedium?.copyWith(color: p.muted),
        ),
        actions: [
          VaultButton(
            label: 'Save receipt',
            loading: controller.flow.busy.value,
            onPressed: () => controller.save(context),
          ),
        ],
        children: [
          const StepBar(step: 2),
          const SizedBox(height: 18),
          Text(
            'Step 2 of 2',
            style: t.labelLarge?.copyWith(
              color: p.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          Semantics(
            header: true,
            child: Text('Check the items', style: t.headlineMedium),
          ),
          const SizedBox(height: 16),
          if (d.items.length > 1)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
              decoration: BoxDecoration(
                color: p.tonal,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  SwitchRow(
                    title: 'Same for all items',
                    subtitle:
                        'Purpose: ${d.sharedPurpose.label}'
                        '${hasPhysical ? ' · Room: ${d.sharedRoomId == null ? 'not set' : controller.roomName(d.sharedRoomId)}' : ''}',
                    value: d.sameForAll,
                    onChanged: controller.flow.setSameForAll,
                  ),
                  if (d.sameForAll)
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => controller.sharedPurpose(context),
                          child: const Text('Change purpose'),
                        ),
                        if (hasPhysical)
                          TextButton(
                            onPressed: () => controller.sharedRoom(context),
                            child: Text(
                              d.sharedRoomId == null
                                  ? 'Choose room'
                                  : 'Change room',
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          if (d.items.isEmpty)
            const EmptyState(
              icon: Icons.list_alt_rounded,
              title: 'No items yet',
              message: 'Add the things you bought so you can find them later.',
            ),
          for (final item in d.items)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: _ItemCard(
                item: item,
                currency: d.currency,
                roomName: controller.roomName,
                carName: controller.store.car(item.carId)?.name,
                canView: item.lineBox != null && d.pages.isNotEmpty,
                onEdit: () => controller.edit(item),
                onView: () => LocalPagesViewer.open(d.pages, box: item.lineBox),
              ),
            ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: controller.add,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add an item'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          if (!d.itemsMatchTotal)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: InfoNote(
                'Items add up to ${Money.format(d.itemsTotal, currency: d.currency)}; '
                'the receipt total is ${Money.format(d.totalMinor!, currency: d.currency)}. '
                "That's fine if there were discounts or delivery.",
                warning: true,
              ),
            ),
        ],
      );
    });
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.item,
    required this.currency,
    required this.roomName,
    required this.onEdit,
    required this.onView,
    required this.canView,
    this.carName,
  });

  final DraftItem item;
  final String currency;
  final String Function(String?) roomName;
  final VoidCallback onEdit;
  final VoidCallback onView;
  final bool canView;
  final String? carName;

  bool get _warrantyWorthAsking =>
      item.warrantyEnd == null &&
      item.isPhysical &&
      const {
        Category.electronics,
        Category.appliances,
        Category.furniture,
        Category.jewellery,
      }.contains(item.category);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final price = item.unitPriceMinor ?? item.lineTotalMinor;
    final rooms = item.allocations.isEmpty
        ? null
        : item.isSplit
        ? item.allocations.entries
              .map((e) => '${roomName(e.key)} ${e.value}')
              .join(', ')
        : roomName(item.roomId);
    return VaultCard(
      onTap: onEdit,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name.isEmpty ? 'Unnamed item' : item.name,
                      style: context.textStyles.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${item.quantity} × ${price == null ? 'price not stated' : Money.format(price, currency: currency)} · ${item.category.label}',
                      style: TextStyle(color: p.muted, fontSize: 16),
                    ),
                  ],
                ),
              ),
              SquareIconButton(
                icon: Icons.edit_outlined,
                tooltip: 'Edit ${item.name}',
                onPressed: onEdit,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Pill(item.type.label),
              Pill(
                item.purpose == Purpose.car && carName != null
                    ? 'Car · $carName'
                    : item.purpose.label,
              ),
              if (item.isPhysical && item.inHome)
                Pill(
                  rooms ?? 'Choose room',
                  tone: rooms == null ? PillTone.amber : PillTone.neutral,
                ),
              if (item.warrantyEnd != null)
                Pill(
                  'Warranty to ${Formatters.medium(item.warrantyEnd!)}',
                  tone: PillTone.green,
                ),
              if (_warrantyWorthAsking)
                GestureDetector(
                  onTap: onEdit,
                  child: const Pill('+ Warranty', tone: PillTone.amber),
                ),
              if (item.highValue)
                const Pill('High value', tone: PillTone.amber),
            ],
          ),
          if (canView)
            TextButton(
              onPressed: onView,
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: const Text('View on receipt'),
            ),
        ],
      ),
    );
  }
}

enum DuplicateChoice { discard, keepBoth, open }

/// 15 Duplicate warning. The user decides; nothing is merged.
class DuplicateDialog extends StatelessWidget {
  const DuplicateDialog({super.key, required this.saved, required this.draft});

  final Receipt saved;
  final ReceiptDraft draft;

  static Future<DuplicateChoice?> show(
    BuildContext context, {
    required Receipt saved,
    required ReceiptDraft draft,
  }) => showDialog<DuplicateChoice>(
    context: context,
    builder: (_) => DuplicateDialog(saved: saved, draft: draft),
  );

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.textStyles;
    final sameFile = saved.checksum != null && saved.checksum == draft.checksum;
    Widget column(String heading, List<String> lines) => Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: p.background,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              heading,
              style: TextStyle(
                color: p.muted,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 6),
            for (final l in lines)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(l, style: const TextStyle(fontSize: 16)),
              ),
          ],
        ),
      ),
    );
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconTile(
              Icons.copy_rounded,
              size: 64,
              color: p.warningSurface,
              iconColor: p.warningInk,
            ),
            const SizedBox(height: 20),
            Text(
              'This looks like a receipt you saved'
              '${saved.confirmedAt == null ? '' : ' on ${Formatters.shortDate(saved.confirmedAt!)}'}',
              style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Text(
              sameFile
                  ? 'It is the same file. If you bought the same things twice, keep both.'
                  : 'Same shop, date and total. If you bought the same things twice, keep both.',
              style: t.bodyLarge?.copyWith(color: p.muted),
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                column('SAVED', [
                  saved.displayShop,
                  Formatters.mediumOrNotStated(saved.purchaseDate),
                  saved.totalMinor == null
                      ? 'Total not stated'
                      : Money.format(
                          saved.totalMinor!,
                          currency: saved.currency,
                        ),
                  saved.number,
                ]),
                const SizedBox(width: 12),
                column('THIS ONE', [
                  draft.shop ?? 'Shop not stated',
                  Formatters.mediumOrNotStated(draft.purchaseDate),
                  draft.totalMinor == null
                      ? 'Total not stated'
                      : Money.format(
                          draft.totalMinor!,
                          currency: draft.currency,
                        ),
                  Formatters.count(draft.items.length, 'item'),
                ]),
              ],
            ),
            const SizedBox(height: 20),
            VaultButton(
              label: "Don't save this copy",
              onPressed: () => Navigator.pop(context, DuplicateChoice.discard),
            ),
            const SizedBox(height: 12),
            VaultButton.secondary(
              label: 'Keep both',
              onPressed: () => Navigator.pop(context, DuplicateChoice.keepBoth),
            ),
            const SizedBox(height: 4),
            Center(
              child: LinkButton(
                label: 'Open the saved receipt',
                onPressed: () => Navigator.pop(context, DuplicateChoice.open),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
