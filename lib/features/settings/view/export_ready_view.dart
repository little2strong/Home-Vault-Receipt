import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/receipt_illustration.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/export_controller.dart';

/// 49 · Export ready
class ExportReadyView extends GetView<ExportController> {
  const ExportReadyView({super.key});

  @override
  Widget build(BuildContext context) {
    final a = controller.archive.value;
    if (a == null) return const VaultPage(title: 'No export yet');
    return VaultPage(
      title: 'Your export is ready.',
      subtitle: 'Copy it privately before the link expires.',
      actions: [
        if (a.json != null && a.csv != null)
          VaultButton.secondary(
            label: 'Copy JSON',
            onPressed: controller.copyJson,
          ),
        VaultButton(
          label: a.csv != null ? 'Copy CSV' : 'Copy JSON',
          onPressed: a.csv != null ? controller.copyCsv : controller.copyJson,
        ),
      ],
      children: [
        const ReceiptIllustration(height: 150),
        InfoCard(
          title: 'Home Vault export',
          subtitle:
              '${Formatters.count(a.receiptCount, 'receipt')} · '
              '${Formatters.fileSize(a.sizeBytes)}',
        ),
        InfoCard(title: 'Expires', subtitle: controller.expiresLabel),
        InfoCard(
          title: 'Keep it safe',
          subtitle: a.includesOriginals
              ? 'The archive contains personal documents. Original files are '
                    'added when downloads are available.'
              : 'The archive contains personal purchase details.',
        ),
      ],
    );
  }
}
