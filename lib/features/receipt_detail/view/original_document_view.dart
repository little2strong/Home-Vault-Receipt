import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/vault_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/receipt_paper.dart';
import '../../../core/widgets/route_view.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/receipt_detail_controller.dart';

/// 33 · Original receipt (image) and 34 · Original PDF.
class OriginalDocumentView extends RouteView<ReceiptDetailController> {
  const OriginalDocumentView({super.key});

  @override
  Widget buildWith(BuildContext context, ReceiptDetailController controller) {
    return Obx(() {
      final r = controller.receipt;
      if (r == null) return const VaultPage(title: 'Original unavailable');
      final pdf = controller.isPdf;
      final pages = controller.pageCount;
      final page = controller.page.value;
      final subtitle = pdf
          ? '${r.retailer} · page ${page + 1} of $pages'
          : '${r.retailer} · ${Formatters.count(pages, 'image')} · pinch to zoom';

      return VaultPage(
        title: pdf ? 'Original invoice' : 'Original receipt',
        subtitle: subtitle,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: InteractiveViewer(
              maxScale: 4,
              child: RotatedBox(
                quarterTurns: controller.quarterTurns.value,
                child: page == 0
                    ? ReceiptPaper.fromReceipt(r)
                    : _TermsPage(page: page + 1),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              const StatusChip(label: 'Original document'),
              TextButton.icon(
                onPressed: controller.rotate,
                icon: const Icon(Icons.rotate_right_rounded),
                label: const Text('Rotate'),
              ),
              if (pages > 1) ...[
                IconButton(
                  tooltip: 'Previous page',
                  onPressed: page == 0 ? null : controller.previousPage,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                IconButton(
                  tooltip: 'Next page',
                  onPressed: page >= pages - 1 ? null : controller.nextPage,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ],
          ),
        ],
      );
    });
  }
}

/// Later pages of a sample PDF.
class _TermsPage extends StatelessWidget {
  const _TermsPage({required this.page});

  final int page;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      height: 360,
      padding: const EdgeInsets.all(18),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TERMS AND WARRANTY',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF173B35),
            ),
          ),
          const SizedBox(height: 12),
          for (final f in const [1.0, 0.9, 0.95, 0.7, 1.0, 0.85, 0.6])
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FractionallySizedBox(
                widthFactor: f,
                child: Container(height: 6, color: p.outline),
              ),
            ),
          const Spacer(),
          Text(
            'Sample source document · page $page',
            style: const TextStyle(fontSize: 9, color: Color(0xFF5F6B67)),
          ),
        ],
      ),
    );
  }
}
