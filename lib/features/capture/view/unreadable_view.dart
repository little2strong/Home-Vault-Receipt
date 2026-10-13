import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/receipt_illustration.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/capture_controller.dart';

/// 39 · Unreadable receipt
class UnreadableView extends GetView<CaptureController> {
  const UnreadableView({super.key});

  @override
  Widget build(BuildContext context) {
    return VaultPage(
      title: 'A clearer photo\nwill help.',
      subtitle: 'Some printed details could not be recognised.',
      actions: [
        VaultButton(label: 'Retake photo', onPressed: controller.retakePhoto),
      ],
      children: [
        const ReceiptIllustration(height: 170),
        const InfoCard(
          title: 'Try good light',
          subtitle: 'Flatten the receipt and avoid glare.',
        ),
        InfoCard(
          title: 'Or enter it yourself',
          subtitle: 'You can save an incomplete record.',
          onTap: controller.enterManually,
        ),
      ],
    );
  }
}
