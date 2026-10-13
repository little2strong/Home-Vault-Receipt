import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/vault_blocks.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/household_controller.dart';

/// 97 · Activity history
class ActivityView extends GetView<HouseholdController> {
  const ActivityView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => VaultPage(
        title: 'What changed, and\nwhen.',
        subtitle: 'Main home · account activity',
        roadmap: true,
        children: [
          for (final a in controller.activity)
            StepTile(badge: a.when, title: a.title, detail: a.detail),
        ],
      ),
    );
  }
}
