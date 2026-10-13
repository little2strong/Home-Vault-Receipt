import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_fields.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/protection_controller.dart';

/// 72 · Maintenance record
class MaintenanceRecordView extends GetView<ProtectionController> {
  const MaintenanceRecordView({super.key});

  @override
  Widget build(BuildContext context) {
    return VaultPage(
      title: 'Log the work.',
      subtitle: 'Keep servicing evidence with the item.',
      roadmap: true,
      actions: [
        VaultButton(
          label: 'Save maintenance',
          onPressed: controller.saveMaintenance,
        ),
      ],
      children: [
        Form(
          key: controller.formKey,
          child: Obx(
            () => Column(
              children: [
                VaultSelectField(
                  label: 'Item',
                  value: controller.item.value ?? 'Choose item',
                  placeholder: controller.item.value == null,
                  onTap: () => controller.pickItem(context),
                ),
                VaultTextField(
                  label: 'Work performed',
                  hint: 'e.g. Descaled and filter replaced',
                  controller: controller.workController,
                  validator: Validators.required,
                ),
                VaultSelectField(
                  label: 'Date',
                  value: Formatters.date(
                    controller.date.value ?? controller.today,
                  ),
                  icon: Icons.calendar_today_outlined,
                  onTap: () => controller.pickDateFor(context, controller.date),
                ),
                VaultTextField(
                  label: 'Cost',
                  hint: 'Optional',
                  controller: controller.costController,
                  validator: Validators.optionalAmount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                VaultSelectField(
                  label: 'Next service',
                  value: controller.nextService.value == null
                      ? 'Not scheduled'
                      : Formatters.date(controller.nextService.value!),
                  placeholder: controller.nextService.value == null,
                  icon: Icons.calendar_today_outlined,
                  onTap: () => controller.pickDateFor(
                    context,
                    controller.nextService,
                    future: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
