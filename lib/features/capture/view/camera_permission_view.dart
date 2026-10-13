import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/receipt_illustration.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/capture_controller.dart';

/// 16 · Camera permission
class CameraPermissionView extends GetView<CaptureController> {
  const CameraPermissionView({super.key});

  @override
  Widget build(BuildContext context) {
    return VaultPage(
      title: 'Ready to scan?',
      subtitle: 'Camera access is used when you take a receipt photo.',
      actions: [
        VaultButton(label: 'Allow camera', onPressed: controller.allowCamera),
      ],
      children: [
        const ReceiptIllustration(height: 170),
        InfoCard(
          title: 'You are in control',
          subtitle: 'You can import an image instead.',
          onTap: () {
            Get.back();
            controller.choosePhotos();
          },
        ),
        const InfoCard(
          title: 'Private by default',
          subtitle: 'Review your record before saving it.',
        ),
      ],
    );
  }
}
