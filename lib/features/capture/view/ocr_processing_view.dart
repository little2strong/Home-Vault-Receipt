import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/vault_palette.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/vault_blocks.dart';
import '../../../core/widgets/vault_header.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/capture_controller.dart';

/// 22 · OCR processing
class OcrProcessingView extends GetView<CaptureController> {
  const OcrProcessingView({super.key});

  static const _stages = [
    ('Photo recognised', 'Text detected on your device.'),
    ('Organising details', 'Matching products, dates and amounts.'),
    ('Next: your review', 'Nothing is confirmed automatically.'),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) controller.cancelReading();
      },
      child: VaultPage(
        header: const VaultHeader.back(),
        title: 'Reading your receipt.',
        subtitle: 'You will check every detail before it is saved.',
        children: [
          Obx(
            () => ProgressCard(
              title: 'Processing your document',
              value: controller.ocrProgress.value,
            ),
          ),
          Obx(() {
            final stage = controller.ocrStage.value;
            return Column(
              children: [
                for (var i = 0; i < _stages.length; i++)
                  InfoCard(
                    title: _stages[i].$1,
                    subtitle: _stages[i].$2,
                    trailing: i < stage
                        ? Icon(Icons.check_circle_rounded, color: p.primary)
                        : i == stage
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const SizedBox.shrink(),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
