import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/route_view.dart';
import '../../../core/widgets/vault_blocks.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/saving_controller.dart';

/// 30 · Saving
class SavingView extends RouteView<SavingController> {
  const SavingView({super.key});

  @override
  Widget buildWith(BuildContext context, SavingController controller) {
    return Obx(() {
      final progress = controller.progress.value;
      final percent = (progress * 100).round();
      final hasDocs = controller.hasDocuments;
      return VaultPage(
        title: 'Putting it safely away.',
        subtitle: hasDocs
            ? 'Uploading the original and confirming your record.'
            : 'Confirming your record.',
        children: [
          ProgressCard(
            title: 'Saving your receipt',
            value: progress == 0 ? null : progress,
          ),
          const InfoCard(
            title: 'Receipt details',
            subtitle: 'Stored on this device',
          ),
          InfoCard(
            title: 'Original document',
            subtitle: !hasDocs
                ? 'No original attached'
                : progress >= 1
                ? 'Uploaded · verified'
                : 'Uploading · $percent%',
          ),
          InfoCard(
            title: 'Saved status',
            subtitle: controller.finished.value
                ? 'Done'
                : 'Waiting for upload verification',
          ),
        ],
      );
    });
  }
}
