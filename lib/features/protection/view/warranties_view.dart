import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/protection_controller.dart';

/// 69 · Warranties
class WarrantiesView extends GetView<ProtectionController> {
  const WarrantiesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final today = controller.today;
      return VaultPage(
        title: 'Know what is\ncovered.',
        subtitle: 'User-confirmed warranty information.',
        roadmap: true,
        children: [
          for (final p in controller.warranties)
            InfoCard(
              title: p.name,
              subtitle: p.warrantyExpiry == null
                  ? 'Terms missing · add document'
                  : p.warrantyExpiry!.isBefore(today)
                  ? 'Ended ${Formatters.date(p.warrantyExpiry!)}'
                  : 'Ends ${Formatters.date(p.warrantyExpiry!)}',
              tone: p.warrantyExpiry == null
                  ? CardTone.warning
                  : CardTone.plain,
              onTap: () => p.warrantyExpiry == null
                  ? controller.openDocuments(p.id)
                  : controller.openWarranty(p),
            ),
        ],
      );
    });
  }
}
