import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/route_view.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/possession_detail_controller.dart';

/// 59 · Documents
class ItemDocumentsView extends RouteView<PossessionDetailController> {
  const ItemDocumentsView({super.key});

  @override
  Widget buildWith(
    BuildContext context,
    PossessionDetailController controller,
  ) {
    return Obx(() {
      final p = controller.possession;
      final receipt = controller.receipt;
      return VaultPage(
        title: 'Proof, together.',
        subtitle: p == null ? null : 'Documents attached to ${p.name}.',
        roadmap: true,
        actions: [
          VaultButton(
            label: 'Add document',
            onPressed: controller.startExtraction,
          ),
        ],
        children: [
          if (receipt != null)
            InfoCard(
              title: 'Original receipt',
              subtitle: '${receipt.retailer} · ${receipt.source.label}',
              onTap: controller.openReceipt,
            ),
          for (final d in p?.documents ?? const [])
            if (!(receipt != null && d.title == 'Original receipt'))
              InfoCard(
                title: d.title,
                subtitle: d.detail,
                tone: d.missing ? CardTone.warning : CardTone.plain,
              ),
          if ((p?.documents.isEmpty ?? true) && receipt == null)
            const InfoCard(
              title: 'No documents yet',
              subtitle: 'Add a receipt, warranty or manual.',
            ),
        ],
      );
    });
  }
}
