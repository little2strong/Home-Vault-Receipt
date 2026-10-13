import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/vault_blocks.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/capture_controller.dart';

/// 20 · PDF import
class PdfImportView extends GetView<CaptureController> {
  const PdfImportView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final file = controller.pdf.value;
      return VaultPage(
        title: 'Your invoice,\nimported.',
        subtitle: 'Check the document before extraction.',
        actions: [
          VaultButton(
            label: 'Read PDF',
            onPressed: file == null ? null : controller.readPdf,
          ),
        ],
        children: [
          const DocumentPreviewCard(icon: Icons.picture_as_pdf_outlined),
          if (file != null) ...[
            InfoCard(
              title: file.fileName,
              subtitle:
                  '${Formatters.count(file.pageCount, 'page')} · '
                  '${Formatters.fileSize(file.sizeBytes)}',
            ),
            for (var page = 1; page <= file.pageCount; page++)
              InfoCard(
                title: 'Page $page',
                subtitle: page == 1 ? 'Purchase details' : 'Terms and warranty',
              ),
          ],
        ],
      );
    });
  }
}
