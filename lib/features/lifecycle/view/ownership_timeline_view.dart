import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/route_view.dart';
import '../../../core/widgets/vault_blocks.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/lifecycle_controller.dart';

/// 81 · Ownership timeline
class OwnershipTimelineView extends RouteView<LifecycleController> {
  const OwnershipTimelineView({super.key});

  @override
  Widget buildWith(BuildContext context, LifecycleController controller) {
    return Obx(
      () => VaultPage(
        title: 'The life of an item.',
        subtitle:
            '${controller.possession?.name ?? ''} · permanent ownership history',
        roadmap: true,
        children: [
          for (final e in controller.timeline)
            StepTile(badge: e.label, title: e.title, detail: e.detail),
        ],
      ),
    );
  }
}
