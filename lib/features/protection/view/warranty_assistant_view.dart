import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/vault_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/route_view.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/protection_controller.dart';

/// 70 · Warranty assistant
class WarrantyAssistantView extends GetView<ProtectionController> {
  const WarrantyAssistantView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = controller.possession(routeArgument<String>(context));
    if (p == null) return const VaultPage(title: 'Item not found');
    return VaultPage(
      title: p.name,
      subtitle: p.warrantyExpiry == null
          ? 'No warranty date confirmed'
          : 'Warranty ends ${Formatters.date(p.warrantyExpiry!)}',
      roadmap: true,
      actions: [
        VaultButton(
          label: 'View warranty documents',
          onPressed: () => controller.openDocuments(p.id),
        ),
      ],
      children: [
        InfoCard(
          title: 'Purchase evidence',
          subtitle: p.hasReceipt
              ? '${p.retailer ?? 'Store'} receipt attached'
              : 'No receipt attached',
          onTap: p.hasReceipt ? () => controller.openReceipt(p) : null,
        ),
        const InfoCard(
          title: 'Manufacturer support',
          subtitle: 'Verify official support link',
        ),
        InfoCard(
          title: 'Serial number',
          subtitle: p.serialNumber ?? 'Not recorded',
        ),
        const InfoCard(
          title: 'Coverage terms',
          subtitle: 'Read before submitting a claim',
        ),
        const SizedBox(height: 8),
        Text(
          'Manufacturer coverage depends on the warranty terms. Check the '
          'source documents before a claim.',
          style: context.textStyles.bodySmall,
        ),
      ],
    );
  }
}
