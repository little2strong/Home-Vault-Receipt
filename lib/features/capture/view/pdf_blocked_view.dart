import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/receipt_illustration.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/capture_controller.dart';

/// 21 · PDF blocked
class PdfBlockedView extends GetView<CaptureController> {
  const PdfBlockedView({super.key});

  @override
  Widget build(BuildContext context) {
    return VaultPage(
      title: 'This PDF is locked.',
      subtitle: 'We cannot read a password-protected document.',
      actions: [
        VaultButton(
          label: 'Choose another file',
          onPressed: () {
            controller.chooseAnotherFile();
            controller.choosePdf();
          },
        ),
      ],
      children: const [
        ReceiptIllustration(height: 170),
        InfoCard(
          title: 'Supply an unlocked copy',
          subtitle: 'Export the PDF without password protection.',
        ),
        InfoCard(
          title: 'Your vault is unchanged',
          subtitle: 'No receipt has been saved.',
        ),
      ],
    );
  }
}
