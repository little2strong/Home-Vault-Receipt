import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/models/receipt_draft.dart';
import '../../../core/parsing/receipt_parser.dart';
import '../../../core/services/capture_service.dart';
import '../../../core/theme/vault_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/vault_ui.dart';
import '../controller/capture_flow.dart';

/// One typed-in item row.
class ManualLine {
  ManualLine()
    : name = TextEditingController(),
      qty = TextEditingController(text: '1'),
      price = TextEditingController();

  final TextEditingController name;
  final TextEditingController qty;
  final TextEditingController price;

  void dispose() {
    name.dispose();
    qty.dispose();
    price.dispose();
  }
}

class ManualController extends GetxController {
  CaptureFlow get flow => CaptureFlow.to;
  ReceiptDraft get d => flow.draft;

  final shop = TextEditingController();
  final total = TextEditingController();
  final date = Rxn<DateTime>();
  final currency = 'GBP'.obs;
  final lines = <ManualLine>[ManualLine()].obs;
  final photoAttached = false.obs;

  @override
  void onInit() {
    super.onInit();
    currency.value = d.currency;
    shop.text = d.shop ?? '';
    date.value = d.purchaseDate;
  }

  void addLine() => lines.add(ManualLine());

  void removeLine(ManualLine l) {
    if (lines.length == 1) return;
    lines.remove(l);
    l.dispose();
  }

  Future<void> attachPhoto() async {
    final picked = await Get.find<CaptureService>().pickItemPhoto(
      camera: false,
    );
    if (picked == null) return;
    final page = await Get.find<CaptureService>().keepBytes(
      d.id,
      await picked.readAsBytes(),
    );
    d.pages.add(page);
    flow.touch();
    photoAttached.value = true;
  }

  /// Manual entry uses the same review screen as a scan.
  void next() {
    d.shop = shop.text.trim().isEmpty ? null : shop.text.trim();
    d.purchaseDate = date.value;
    d.currency = currency.value;
    d.totalMinor = Money.parse(total.text);
    var n = 0;
    d.items = [
      for (final l in lines)
        if (l.name.text.trim().isNotEmpty)
          () {
            final qty = int.tryParse(l.qty.text.trim()) ?? 1;
            final unit = Money.parse(l.price.text);
            final category = ReceiptParser.guessCategory(
              l.name.text,
              shop: d.shop,
            );
            return DraftItem(
              id: 'm${n++}',
              name: l.name.text.trim(),
              category: category,
              quantity: qty < 1 ? 1 : qty,
              unitPriceMinor: unit,
              lineTotalMinor: unit == null ? null : unit * (qty < 1 ? 1 : qty),
            );
          }(),
    ];
    if (d.totalMinor == null && d.items.isNotEmpty) {
      Toast.show('Add the total paid, or leave it as Not stated.');
    }
    flow.touch();
    Get.toNamed(Routes.reviewItems);
  }

  @override
  void onClose() {
    shop.dispose();
    total.dispose();
    for (final l in lines) {
      l.dispose();
    }
    super.onClose();
  }
}

/// 17 Manual entry: a receipt typed in without a scan.
class ManualView extends GetView<ManualController> {
  const ManualView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppPage(
      title: 'Type in a receipt',
      onBack: () => controller.flow.leave(),
      actions: [
        VaultButton(label: 'Next: check items', onPressed: controller.next),
      ],
      children: [
        LabeledField(
          label: 'Shop',
          controller: controller.shop,
          hint: 'e.g. Argos',
          textCapitalization: TextCapitalization.words,
        ),
        Obx(
          () => Row(
            children: [
              Expanded(
                flex: 3,
                child: PickerField(
                  label: 'Date',
                  value: controller.date.value == null
                      ? null
                      : Formatters.medium(controller.date.value!),
                  placeholder: 'DD MMM YYYY',
                  icon: Icons.calendar_today_outlined,
                  onTap: () async {
                    final d = await Pickers.date(
                      context,
                      initial: controller.date.value,
                      last: DateTime.now(),
                    );
                    if (d != null) controller.date.value = d;
                  },
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 2,
                child: PickerField(
                  label: 'Currency',
                  value:
                      '${controller.currency.value} ${Money.symbolFor(controller.currency.value).trim()}',
                  onTap: () async {
                    final c = await Pickers.currency(
                      context,
                      controller.currency.value,
                    );
                    if (c != null) controller.currency.value = c;
                  },
                ),
              ),
            ],
          ),
        ),
        LabeledField(
          label: 'Total paid',
          controller: controller.total,
          hint: '0.00',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 20),
        Text('Items', style: context.textStyles.titleMedium),
        const SizedBox(height: 10),
        Obx(
          () => Column(
            children: [
              for (final l in controller.lines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: VaultCard(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: l.name,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                decoration: const InputDecoration(
                                  hintText: 'Item name',
                                ),
                              ),
                            ),
                            if (controller.lines.length > 1)
                              IconButton(
                                tooltip: 'Remove item',
                                onPressed: () => controller.removeLine(l),
                                icon: const Icon(Icons.close_rounded),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            SizedBox(
                              width: 90,
                              child: TextField(
                                controller: l.qty,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  hintText: '1',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: l.price,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: const InputDecoration(
                                  hintText: 'Price',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        OutlinedButton(
          onPressed: controller.addLine,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            foregroundColor: p.ink,
            side: BorderSide(color: p.muted),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text(
            '+ Add another item',
            style: TextStyle(fontSize: 17),
          ),
        ),
        const SizedBox(height: 12),
        Obx(
          () => Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: controller.attachPhoto,
              icon: Icon(
                controller.photoAttached.value
                    ? Icons.check_circle_outline_rounded
                    : Icons.photo_camera_outlined,
              ),
              label: Text(
                controller.photoAttached.value
                    ? 'Photo of the receipt attached'
                    : 'Attach a photo of the receipt (optional)',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
