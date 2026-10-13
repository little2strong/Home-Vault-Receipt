import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/vault_palette.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/capture_controller.dart';
import '../widgets/sample_receipt_paper.dart';
import '../widgets/viewfinder.dart';

/// 18 · Crop receipt
class CropView extends GetView<CaptureController> {
  const CropView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return VaultPage(
      title: 'Straighten the\ndetails.',
      subtitle: 'Adjust the edges. Your original is preserved.',
      actions: [
        VaultButton.secondary(label: 'Retake', onPressed: Get.back),
        VaultButton(label: 'Use this photo', onPressed: controller.usePhoto),
      ],
      children: [
        Obx(
          () => Viewfinder(
            semanticLabel: 'Captured receipt photo',
            child: DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                border: controller.showEdges.value
                    ? Border.all(color: p.primary, width: 2)
                    : null,
              ),
              child: const SampleReceiptPaper(),
            ),
          ),
        ),
        Obx(
          () => SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Adjust edges'),
            subtitle: const Text('Show the detected receipt outline'),
            value: controller.showEdges.value,
            onChanged: (_) => controller.toggleEdges(),
          ),
        ),
      ],
    );
  }
}
