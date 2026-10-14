import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdfx/pdfx.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/item.dart';
import '../../../core/models/receipt_draft.dart';
import '../../../core/theme/vault_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/vault_ui.dart';
import '../controller/capture_flow.dart';

class ReviewDetailsController extends GetxController {
  CaptureFlow get flow => CaptureFlow.to;
  ReceiptDraft get d => flow.draft;

  late final shop = TextEditingController(text: d.shop);
  late final total = TextEditingController(
    text: d.totalMinor == null ? '' : Money.toInput(d.totalMinor!),
  );
  late final vat = TextEditingController(
    text: d.taxMinor == null ? '' : Money.toInput(d.taxMinor!),
  );
  late final order = TextEditingController(text: d.orderNumber);
  final totalError = RxnString();

  void sync() {
    d.shop = shop.text.trim().isEmpty ? null : shop.text.trim();
    d.totalMinor = Money.parse(total.text);
    d.taxMinor = Money.parse(vat.text);
    d.orderNumber = order.text.trim().isEmpty ? null : order.text.trim();
    flow.touch();
  }

  Future<void> pickDate(BuildContext context) async {
    final picked = await Pickers.date(
      context,
      initial: d.purchaseDate,
      last: DateTime.now(),
      help: 'Date on the receipt',
    );
    if (picked == null) return;
    d.purchaseDate = picked;
    d.extracted['dateAmbiguous'] = false;
    flow.touch();
  }

  /// Day and month swapped, for `05/06/26` style dates.
  void swapDayMonth() {
    final date = d.purchaseDate;
    if (date == null || date.day > 12) return;
    d.purchaseDate = DateTime(date.year, date.day, date.month);
    d.extracted['dateAmbiguous'] = false;
    flow.touch();
  }

  Future<void> pickCurrency(BuildContext context) async {
    final c = await Pickers.currency(context, d.currency);
    if (c == null) return;
    d.currency = c;
    flow.touch();
  }

  /// Only set when the user confirms the receipt's wording.
  void useSuggestedReturn() {
    final s = flow.suggestedReturn;
    if (s == null) return;
    d.returnDeadline = s;
    d.returnFromWording = true;
    flow.touch();
  }

  Future<void> typeReturnDate(BuildContext context) async {
    final picked = await Pickers.date(
      context,
      initial: d.returnDeadline ?? d.purchaseDate,
      first: d.purchaseDate ?? DateTime(2000),
      help: 'Last day to return',
    );
    if (picked == null) return;
    d.returnDeadline = picked;
    d.returnFromWording = false;
    flow.touch();
  }

  void clearReturn() {
    d.returnDeadline = null;
    d.returnFromWording = false;
    flow.touch();
  }

  void next() {
    sync();
    if (total.text.trim().isNotEmpty && d.totalMinor == null) {
      totalError.value = 'Enter the total like 12.50';
      return;
    }
    totalError.value = null;
    Get.toNamed(Routes.reviewItems);
  }

  @override
  void onClose() {
    shop.dispose();
    total.dispose();
    vat.dispose();
    order.dispose();
    super.onClose();
  }
}

/// 12 Review step 1: shop, date, total, currency. Unknowns stay
/// "Not stated"; nothing is saved until the user confirms.
class ReviewDetailsView extends GetView<ReviewDetailsController> {
  const ReviewDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.textStyles;
    final d = controller.d;
    final extracted = d.extracted;
    final scanned = extracted.isNotEmpty;
    return AppPage(
      titleInHeader: false,
      onBack: () => controller.flow.leave(),
      trailing: d.pages.isEmpty
          ? null
          : TextButton.icon(
              onPressed: () => LocalPagesViewer.open(d.pages),
              icon: const Icon(Icons.bookmark_border_rounded),
              label: const Text('View receipt', style: TextStyle(fontSize: 17)),
            ),
      actions: [
        VaultButton(label: 'Next: check items', onPressed: controller.next),
      ],
      children: [
        const StepBar(step: 1),
        const SizedBox(height: 18),
        Text(
          'Step 1 of 2',
          style: t.labelLarge?.copyWith(
            color: p.muted,
            fontWeight: FontWeight.w700,
          ),
        ),
        Semantics(
          header: true,
          child: Text('Check the details', style: t.headlineMedium),
        ),
        const SizedBox(height: 6),
        Text(
          "Fix anything that's wrong. Leave blanks if they're not on the receipt.",
          style: t.bodyLarge?.copyWith(color: p.muted),
        ),
        LabeledField(
          label: 'Shop',
          controller: controller.shop,
          hint: 'Not stated',
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => controller.sync(),
          warning: scanned && extracted['shop'] == null
              ? "Couldn't read this — add it if you can see it"
              : null,
        ),
        Obx(() {
          controller.flow.version.value;
          final ambiguous = controller.flow.dateAmbiguous;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: PickerField(
                      label: 'Date',
                      value: d.purchaseDate == null
                          ? null
                          : Formatters.medium(d.purchaseDate!),
                      icon: Icons.calendar_today_outlined,
                      onTap: () => controller.pickDate(context),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 2,
                    child: PickerField(
                      label: 'Currency',
                      value:
                          '${d.currency} ${Money.symbolFor(d.currency).trim()}',
                      onTap: () => controller.pickCurrency(context),
                    ),
                  ),
                ],
              ),
              if (ambiguous && d.purchaseDate != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: InfoNote(
                    'This date could be read two ways. Is it '
                    '${Formatters.medium(d.purchaseDate!)}?',
                    warning: true,
                    icon: Icons.help_outline_rounded,
                    trailing: TextButton(
                      onPressed: controller.swapDayMonth,
                      child: const Text('Swap day/month'),
                    ),
                  ),
                ),
            ],
          );
        }),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Obx(
                () => LabeledField(
                  label: 'Total paid',
                  controller: controller.total,
                  hint: 'Not stated',
                  bold: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => controller.sync(),
                  warning: controller.totalError.value,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: LabeledField(
                label: 'VAT',
                controller: controller.vat,
                hint: 'Not stated',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) => controller.sync(),
              ),
            ),
          ],
        ),
        LabeledField(
          label: 'Order or receipt number',
          controller: controller.order,
          hint: 'Not stated',
          textCapitalization: TextCapitalization.characters,
          onChanged: (_) => controller.sync(),
          warning: scanned && extracted['orderNumber'] == null
              ? "Couldn't read this — add it if you can see it"
              : null,
        ),
        const SizedBox(height: 18),
        Obx(() {
          controller.flow.version.value;
          return _ReturnCard(controller: controller);
        }),
        const SizedBox(height: 14),
        Obx(() {
          controller.flow.version.value;
          final n = d.items.length;
          if (n == 0) {
            return InfoNote(
              scanned
                  ? 'No items found. You can add them on the next step.'
                  : 'Add the items on the next step.',
              icon: Icons.info_outline_rounded,
            );
          }
          final match = d.itemsMatchTotal;
          return InfoNote(
            match
                ? '${Formatters.count(n, 'item')} found · they add up to the total'
                : '${Formatters.count(n, 'item')} found · they add up to '
                      '${Money.format(d.itemsTotal, currency: d.currency)}, '
                      'not the total. Check them on the next step.',
            icon: null,
            warning: !match,
            trailing: Icon(
              match ? Icons.check_rounded : Icons.error_outline_rounded,
              color: match ? p.primary : p.warningInk,
            ),
          );
        }),
      ],
    );
  }
}

class _ReturnCard extends StatelessWidget {
  const _ReturnCard({required this.controller});

  final ReviewDetailsController controller;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final d = controller.d;
    final suggested = controller.flow.suggestedReturn;
    if (d.returnDeadline != null) {
      return VaultCard(
        child: Row(
          children: [
            Icon(Icons.assignment_return_outlined, color: p.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Return by ${Formatters.medium(d.returnDeadline!)}',
                    style: context.textStyles.titleMedium,
                  ),
                  Text(
                    d.returnFromWording
                        ? 'From the receipt wording'
                        : 'Date you typed',
                    style: TextStyle(color: p.muted),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: controller.clearReturn,
              child: const Text('Remove'),
            ),
          ],
        ),
      );
    }
    if (d.returnWording != null) {
      return VaultCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('The receipt says', style: TextStyle(color: p.muted)),
            const SizedBox(height: 4),
            Text(
              '“${d.returnWording}”',
              style: context.textStyles.bodyLarge?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                if (suggested != null)
                  FilledButton.tonal(
                    onPressed: controller.useSuggestedReturn,
                    child: Text('Return by ${Formatters.medium(suggested)}'),
                  ),
                TextButton(
                  onPressed: () => controller.typeReturnDate(context),
                  child: const Text('Type a date'),
                ),
              ],
            ),
          ],
        ),
      );
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () => controller.typeReturnDate(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add a return date (optional)'),
      ),
    );
  }
}

/// Shows the captured pages before saving, with an item's line marked.
class LocalPagesViewer extends StatelessWidget {
  const LocalPagesViewer({super.key, required this.pages, this.box});

  final List<DraftPage> pages;
  final LineBox? box;

  static Future<void> open(List<DraftPage> pages, {LineBox? box}) =>
      Get.to<void>(
        () => LocalPagesViewer(pages: pages, box: box),
        fullscreenDialog: true,
      )!;

  @override
  Widget build(BuildContext context) {
    final start = (box?.page ?? 0).clamp(0, pages.length - 1);
    return Scaffold(
      backgroundColor: AppColors.camera,
      appBar: AppBar(
        backgroundColor: AppColors.camera,
        foregroundColor: Colors.white,
        title: const Text('Your receipt'),
      ),
      body: pages.length == 1 && pages.first.isPdf
          ? PdfViewPinch(
              controller: PdfControllerPinch(
                document: PdfDocument.openFile(pages.first.localPath),
              ),
            )
          : PageView(
              controller: PageController(initialPage: start),
              children: [
                for (var i = 0; i < pages.length; i++)
                  InteractiveViewer(
                    maxScale: 5,
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: pages[i].width > 0
                            ? pages[i].width / pages[i].height
                            : 0.6,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(
                              File(pages[i].localPath),
                              fit: BoxFit.fill,
                            ),
                            if (box != null && box!.page == i)
                              LineHighlight(box: box!),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

/// The green box around an item's line on the original.
class LineHighlight extends StatelessWidget {
  const LineHighlight({super.key, required this.box});

  final LineBox box;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) => Stack(
      children: [
        Positioned(
          left: (box.x * c.maxWidth) - 6,
          top: (box.y * c.maxHeight) - 4,
          width: box.w * c.maxWidth + 12,
          height: box.h * c.maxHeight + 8,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF206951).withValues(alpha: 0.22),
                border: Border.all(color: const Color(0xFF206951), width: 2.5),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
