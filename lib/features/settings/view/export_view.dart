import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_fields.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/export_controller.dart';

/// 48 · Export selection
class ExportView extends GetView<ExportController> {
  const ExportView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final r = controller.request.value;
      return VaultPage(
        title: 'Take your records\nwith you.',
        subtitle: 'Choose what to include in your export.',
        actions: [
          VaultButton(
            label: 'Create export',
            onPressed: controller.createExport,
          ),
        ],
        children: [
          VaultSelectField(
            label: 'Records',
            value: controller.recordsLabel,
            onTap: () => controller.pickScope(context),
          ),
          VaultSelectField(
            label: 'Data format',
            value: r.format.label,
            onTap: () => controller.pickFormat(context),
          ),
          VaultSelectField(
            label: 'Original documents',
            value: r.includeOriginals ? 'Include' : 'Leave out',
            onTap: () => controller.pickOriginals(context),
          ),
          VaultSelectField(
            label: 'Link expiry',
            value: r.expiry.label,
            onTap: () => controller.pickExpiry(context),
          ),
        ],
      );
    });
  }
}
