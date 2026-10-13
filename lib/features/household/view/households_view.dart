import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/household_controller.dart';

/// 82 · Households
class HouseholdsView extends GetView<HouseholdController> {
  const HouseholdsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => VaultPage(
        title: 'A place for each\nhome.',
        subtitle: 'Keep household records separate.',
        roadmap: true,
        actions: [
          VaultButton(
            label: 'Add household',
            onPressed: () => controller.addHousehold(context),
          ),
        ],
        children: [
          for (final h in controller.households)
            InfoCard(
              title: h.name,
              subtitle: '${Formatters.count(h.itemCount, 'item')} · ${h.role}',
              onTap: controller.openMembers,
            ),
        ],
      ),
    );
  }
}
