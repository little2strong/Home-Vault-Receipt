import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/models/receipt_model.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/vault_blocks.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/pending_controller.dart';

/// 37 · Offline queue, plus drafts waiting for review.
class PendingUploadsView extends GetView<PendingController> {
  const PendingUploadsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final pending = controller.pending;
      final online = controller.isOnline;
      return VaultPage(
        title: pending.isEmpty ? 'All caught up.' : 'Saved on this device.',
        subtitle: pending.isEmpty
            ? 'Every record is safely in your vault.'
            : 'Connect to finish parsing and cloud saving.',
        actions: [
          if (controller.hasUploads)
            VaultButton(
              label: online ? 'Retry upload' : 'Retry connection',
              loading: controller.isRetrying.value,
              onPressed: controller.retry,
            ),
        ],
        children: [
          if (controller.hasUploads)
            NoticeBanner(
              text: online
                  ? 'Connected · ready to upload'
                  : 'Waiting for connection',
            ),
          for (final r in pending)
            InfoCard(
              title: controller.titleFor(r),
              subtitle: r.status.label,
              tone: r.status == ReceiptStatus.failed
                  ? CardTone.warning
                  : CardTone.plain,
              onTap: r.status == ReceiptStatus.queued
                  ? null
                  : () => controller.open(r),
            ),
          if (controller.hasUploads)
            const InfoCard(
              title: 'Your next step',
              subtitle: 'Keep the app installed until uploads finish.',
            ),
        ],
      );
    });
  }
}
