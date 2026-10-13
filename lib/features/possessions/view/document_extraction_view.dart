import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/route_view.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_fields.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/possession_detail_controller.dart';

/// 60 · Document extraction
class DocumentExtractionView extends RouteView<PossessionDetailController> {
  const DocumentExtractionView({super.key});

  @override
  Widget buildWith(
    BuildContext context,
    PossessionDetailController controller,
  ) {
    return Obx(() {
      final isWarranty = controller.docType.value == DocumentType.warranty;
      final expiry = controller.expiry.value;
      return VaultPage(
        title: 'Check document\ndetails.',
        subtitle: 'Review suggestions before applying them.',
        roadmap: true,
        actions: [
          VaultButton(
            label: 'Apply confirmed details',
            onPressed: controller.applyDetails,
          ),
        ],
        children: [
          VaultSelectField(
            label: 'Document type',
            value: controller.docType.value.label,
            onTap: () => controller.pickType(context),
          ),
          VaultSelectField(
            label: 'Product',
            value: controller.possession?.name ?? '',
          ),
          if (isWarranty) ...[
            VaultSelectField(
              label: 'Warranty length',
              value: Formatters.count(controller.warrantyYears.value, 'year'),
              onTap: () => controller.pickWarrantyLength(context),
            ),
            VaultSelectField(
              label: 'Expiry',
              value: expiry == null ? 'Choose date' : Formatters.date(expiry),
              placeholder: expiry == null,
              icon: Icons.calendar_today_outlined,
              onTap: () => controller.pickExpiry(context),
            ),
          ],
          const VaultSelectField(
            label: 'Source',
            value: 'Page 1 · coverage period',
          ),
        ],
      );
    });
  }
}
