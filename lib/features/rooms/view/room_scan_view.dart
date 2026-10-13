import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/vault_palette.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_page.dart';
import '../../capture/widgets/viewfinder.dart';
import '../controller/rooms_controller.dart';

/// 63 · Room scan
class RoomScanView extends GetView<RoomsController> {
  const RoomScanView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return VaultPage(
      title: 'Build a room\ninventory.',
      subtitle: 'Detected objects need your confirmation.',
      roadmap: true,
      actions: [
        VaultButton(label: 'Scan room', onPressed: controller.reviewScan),
      ],
      children: [
        Viewfinder(
          semanticLabel:
              'Camera preview of a living room with three possible objects',
          child: SizedBox(
            height: 220,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ColoredBox(color: p.surface.withValues(alpha: 0.6)),
                ),
                Positioned(
                  left: 16,
                  top: 16,
                  child: Container(
                    width: 110,
                    height: 66,
                    decoration: BoxDecoration(
                      color: p.tonal,
                      border: Border.all(color: p.hero, width: 5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Positioned(
                  left: 10,
                  bottom: 34,
                  child: Container(
                    width: 130,
                    height: 62,
                    decoration: BoxDecoration(
                      color: p.muted.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Positioned(
                  right: 18,
                  bottom: 40,
                  child: Container(
                    width: 60,
                    height: 8,
                    color: p.warningBorder,
                  ),
                ),
                const Positioned(
                  left: 20,
                  bottom: 4,
                  child: StatusChip(label: '3 possible objects'),
                ),
              ],
            ),
          ),
        ),
        const Text('Flash: auto · Keep all edges visible'),
      ],
    );
  }
}
