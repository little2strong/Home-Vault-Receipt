import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/capture_controller.dart';
import '../widgets/sample_receipt_paper.dart';
import '../widgets/viewfinder.dart';

/// 17 · Camera scanner
class ScannerView extends GetView<CaptureController> {
  const ScannerView({super.key});

  @override
  Widget build(BuildContext context) {
    return VaultPage(
      title: 'Keep the whole\nreceipt in view.',
      subtitle: 'Find good light and hold your phone steady.',
      actions: [VaultButton(label: 'Capture', onPressed: controller.capture)],
      children: [
        const Viewfinder(
          semanticLabel: 'Camera preview showing a receipt',
          child: SampleReceiptPaper(),
        ),
        Row(
          children: [
            Obx(
              () => TextButton.icon(
                onPressed: controller.cycleFlash,
                icon: const Icon(Icons.flash_auto_rounded, size: 18),
                label: Text(controller.flash.value.label),
              ),
            ),
            const SizedBox(width: 8),
            const Flexible(child: Text('Keep all edges visible')),
          ],
        ),
      ],
    );
  }
}
