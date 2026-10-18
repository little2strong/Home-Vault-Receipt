import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/data/vault_repository.dart';
import '../../../core/data/vault_store.dart';
import '../../../core/models/receipt.dart';
import '../../../core/theme/vault_palette.dart';
import '../../../core/utils/dates.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/vault_ui.dart';
import '../../start/controller/start_controllers.dart';

class ReceiptDetailController extends GetxController {
  ReceiptDetailController(this.store, this.repo);

  final VaultStore store;
  final VaultRepository repo;
  late final String id = Get.parameters['id'] ?? '';

  Receipt? get receipt => store.receipt(id);

  Future<void> edit() async {
    final r = receipt;
    if (r == null) return;
    final changes = await SheetFrame.show<Map<String, dynamic>>(
      _EditReceiptSheet(receipt: r),
    );
    if (changes == null || changes.isEmpty) return;
    try {
      await repo.updateReceipt(r.id, changes);
      Toast.show('Saved');
    } catch (_) {
      Toast.show('That change did not save. Try again.');
    }
  }

  /// Return deadlines only from wording the user confirms or a typed date.
  Future<void> returnDate(BuildContext context) async {
    final r = receipt;
    if (r == null) return;
    final existing = store.returnFor(r.id);
    final suggestion = _fromWording(r);
    final options = <String>[
      if (suggestion != null) 'wording',
      'type',
      if (existing != null) 'clear',
    ];
    final choice = await Pickers.choose<String>(
      context,
      title: 'Return deadline',
      values: options,
      label: (o) => switch (o) {
        'wording' =>
          'Use the receipt: ${Formatters.medium(suggestion!)} (“${r.returnWording}”)',
        'type' => 'Type a date',
        _ => 'Remove the deadline',
      },
    );
    if (choice == null || !context.mounted) return;
    final label = store.itemsOnReceipt(r.id).firstOrNull?.name;
    if (choice == 'clear') {
      await repo.clearReturnDeadline(r.id);
      return;
    }
    DateTime? date = suggestion;
    if (choice == 'type') {
      date = await Pickers.date(
        context,
        initial: existing?.deadline ?? r.purchaseDate,
        first: r.purchaseDate ?? DateTime(2000),
        help: 'Last day to return',
      );
    }
    if (date == null) return;
    await repo.setReturnDeadline(
      receiptId: r.id,
      deadline: date,
      shop: r.shop,
      label: label,
      sourceText: choice == 'wording' ? r.returnWording : null,
    );
    await askForRemindersOnce();
  }

  DateTime? _fromWording(Receipt r) {
    final w = r.returnWording;
    if (w == null || r.purchaseDate == null) return null;
    final m = RegExp(
      r'(\d{1,3})\s*-?\s*days?',
      caseSensitive: false,
    ).firstMatch(w);
    return m == null
        ? null
        : Dates.addDays(r.purchaseDate!, int.parse(m.group(1)!));
  }

  Future<void> delete(BuildContext context) async {
    final r = receipt;
    if (r == null) return;
    final ok = await Pickers.confirm(
      context,
      title: 'Delete ${r.number}?',
      message:
          'This deletes the receipt, its stored original and its '
          '${Formatters.count(r.itemCount, 'item')}, with their photos and '
          'warranties.',
      action: 'Delete',
      destructive: true,
    );
    if (!ok) return;
    // Pages of this receipt's items (opened before or after it) go too,
    // or the user lands on "This item is no longer here".
    final pages = [
      Routes.receipt(r.id),
      for (final i in store.itemsOnReceipt(r.id)) Routes.item(i.id),
    ];
    try {
      await repo.deleteReceipt(r.id);
      Get.until((route) {
        final name = route.settings.name ?? '';
        final gone = pages.any((p) => name == p || name.startsWith('$p/'));
        return !gone || route.isFirst;
      });
      Toast.show('Receipt deleted');
    } catch (e) {
      Toast.show('$e');
    }
  }
}

/// 22 Receipt detail: receipt info and its items.
class ReceiptDetailView extends GetView<ReceiptDetailController> {
  const ReceiptDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Obx(() {
      final r = controller.receipt;
      if (r == null) {
        return AppPage(
          title: 'Receipt',
          children: [
            controller.store.loaded.value
                ? const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'This receipt is no longer here',
                    message: 'It may have been deleted on another device.',
                  )
                : const Center(child: CircularProgressIndicator()),
          ],
        );
      }
      final items = controller.store.itemsOnReceipt(r.id);
      final ret = controller.store.returnFor(r.id);
      final today = DateTime.now();
      return AppPage(
        eyebrow: 'Receipt ${r.number}',
        title: r.displayShop,
        trailing: SquareIconButton(
          icon: Icons.edit_outlined,
          tooltip: 'Edit receipt',
          onPressed: controller.edit,
        ),
        actions: [
          if (r.hasOriginal)
            VaultButton(
              label: 'View original receipt',
              onPressed: () => Get.toNamed(Routes.original(r.id)),
            ),
        ],
        children: [
          HeroCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total paid',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          money(r.totalMinor, r.currency),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Formatters.mediumOrNotStated(r.purchaseDate),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    Text(
                      r.sourceLine,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ListCard(
            children: [
              DetailRow(
                'VAT',
                r.taxMinor == null
                    ? 'Not stated'
                    : Money.format(r.taxMinor!, currency: r.currency),
                muted: r.taxMinor == null,
              ),
              DetailRow(
                'Order number',
                r.orderNumber ?? 'Not stated',
                muted: r.orderNumber == null,
              ),
              DetailRow(
                'Return by',
                ret == null
                    ? (r.returnWording == null ? 'Not stated' : 'Check wording')
                    : ret.isOpen(today)
                    ? Formatters.medium(ret.deadline)
                    : 'Ended ${Formatters.medium(ret.deadline)}',
                muted: ret == null,
                onTap: () => controller.returnDate(context),
              ),
            ],
          ),
          SectionLabel(Formatters.count(items.length, 'item')),
          if (items.isEmpty)
            Text('No items on this receipt.', style: TextStyle(color: p.muted))
          else
            ListCard(
              children: [
                for (final i in items)
                  RowTile(
                    title: i.displayName,
                    subtitle: [
                      if (i.isPhysical && i.inHome)
                        controller.store.roomLabel(i),
                      if (i.warrantyEnd != null)
                        'warranty to ${i.warrantyEnd!.year}',
                      if (!(i.isPhysical && i.inHome)) i.purpose.label,
                    ].join(' · '),
                    trailingText: money(i.lineTotalMinor, i.currency),
                    onTap: () => Get.toNamed(Routes.item(i.id)),
                  ),
              ],
            ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lock_outline_rounded, size: 18, color: p.muted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  r.hasOriginal
                      ? 'Original stored privately. It only opens when you ask.'
                      : 'Typed in — no original was stored.',
                  style: TextStyle(color: p.muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: LinkButton(
              label: 'Delete this receipt',
              color: p.dangerInk,
              onPressed: () => controller.delete(context),
            ),
          ),
        ],
      );
    });
  }
}

class _EditReceiptSheet extends StatefulWidget {
  const _EditReceiptSheet({required this.receipt});

  final Receipt receipt;

  @override
  State<_EditReceiptSheet> createState() => _EditReceiptSheetState();
}

class _EditReceiptSheetState extends State<_EditReceiptSheet> {
  late final r = widget.receipt;
  late final shop = TextEditingController(text: r.shop);
  late final total = TextEditingController(
    text: r.totalMinor == null ? '' : Money.toInput(r.totalMinor!),
  );
  late final vat = TextEditingController(
    text: r.taxMinor == null ? '' : Money.toInput(r.taxMinor!),
  );
  late final order = TextEditingController(text: r.orderNumber);
  late DateTime? date = r.purchaseDate;
  late String currency = r.currency;

  @override
  Widget build(BuildContext context) {
    return SheetFrame(
      title: 'Edit receipt',
      trailing: const SheetClose(),
      children: [
        LabeledField(label: 'Shop', controller: shop, hint: 'Not stated'),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: PickerField(
                label: 'Date',
                value: date == null ? null : Formatters.medium(date!),
                onTap: () async {
                  final d = await Pickers.date(
                    context,
                    initial: date,
                    last: DateTime.now(),
                  );
                  if (d != null) setState(() => date = d);
                },
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 2,
              child: PickerField(
                label: 'Currency',
                value: currency,
                onTap: () async {
                  final c = await Pickers.currency(context, currency);
                  if (c != null) setState(() => currency = c);
                },
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: LabeledField(
                label: 'Total paid',
                controller: total,
                hint: 'Not stated',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: LabeledField(
                label: 'VAT',
                controller: vat,
                hint: 'Not stated',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ),
          ],
        ),
        LabeledField(
          label: 'Order number',
          controller: order,
          hint: 'Not stated',
        ),
        const SizedBox(height: 20),
        VaultButton(
          label: 'Save changes',
          onPressed: () {
            final s = shop.text.trim();
            final o = order.text.trim();
            Get.back(
              result: {
                'shop': s.isEmpty ? null : s,
                'purchaseDate': date == null ? null : Dates.toIso(date!),
                'currency': currency,
                'totalMinor': Money.parse(total.text),
                'taxMinor': Money.parse(vat.text),
                'orderNumber': o.isEmpty ? null : o,
              },
            );
          },
        ),
      ],
    );
  }
}
