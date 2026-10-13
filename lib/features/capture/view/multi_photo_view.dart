import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/document_service.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/vault_blocks.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/capture_controller.dart';

/// 19 · Multi photo: one receipt, several photos, in reading order.
class MultiPhotoView extends GetView<CaptureController> {
  const MultiPhotoView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final pages = controller.pages;
      return VaultPage(
        title: 'One receipt,\nseveral photos.',
        subtitle: 'Keep the page order correct.',
        actions: [
          VaultButton(
            label: 'Read receipt',
            onPressed: pages.isEmpty ? null : controller.readPhotos,
          ),
        ],
        children: [
          const DocumentPreviewCard(),
          for (var i = 0; i < pages.length; i++)
            InfoCard(
              title: 'Photo ${i + 1}',
              subtitle: '${controller.pageNote(i)} · ${pages[i].fileName}',
              trailing: _PageActions(
                index: i,
                count: pages.length,
                onMove: controller.movePage,
                onRemove: controller.removePage,
              ),
            ),
          InfoCard(
            title: 'Add another photo',
            subtitle: controller.canAddPage
                ? 'Maximum ${DocumentService.maxPhotos} photos per receipt'
                : 'You have reached ${DocumentService.maxPhotos} photos',
            onTap: controller.canAddPage ? controller.addAnotherPhoto : null,
            leading: const Icon(Icons.add_a_photo_outlined),
          ),
        ],
      );
    });
  }
}

class _PageActions extends StatelessWidget {
  const _PageActions({
    required this.index,
    required this.count,
    required this.onMove,
    required this.onRemove,
  });

  final int index;
  final int count;
  final void Function(int from, int to) onMove;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Move photo ${index + 1} up',
          onPressed: index == 0 ? null : () => onMove(index, index - 1),
          icon: const Icon(Icons.arrow_upward_rounded),
        ),
        IconButton(
          tooltip: 'Move photo ${index + 1} down',
          onPressed: index == count - 1 ? null : () => onMove(index, index + 1),
          icon: const Icon(Icons.arrow_downward_rounded),
        ),
        IconButton(
          tooltip: 'Remove photo ${index + 1}',
          onPressed: () => onRemove(index),
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }
}
