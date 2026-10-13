import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/models/ownership_models.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/route_view.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_fields.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/lifecycle_controller.dart';

/// 92 · Ownership status
class OwnershipStatusView extends RouteView<LifecycleController> {
  const OwnershipStatusView({super.key});

  @override
  Widget buildWith(BuildContext context, LifecycleController controller) {
    return VaultPage(
      title: 'What happened to\nthis item?',
      subtitle: 'Keep the history even after it leaves your home.',
      roadmap: true,
      actions: [
        VaultButton(
          label: 'Save ownership change',
          onPressed: controller.saveStatus,
        ),
      ],
      children: [
        Obx(() {
          final sold = controller.status.value == OwnershipStatus.sold;
          final date = controller.saleDate.value;
          return Column(
            children: [
              VaultSelectField(
                label: 'Status',
                value: controller.status.value.label,
                onTap: () => controller.pickStatus(context),
              ),
              if (controller.status.value != OwnershipStatus.owned)
                VaultSelectField(
                  label: sold ? 'Sale date' : 'Date',
                  value: date == null ? 'Choose date' : Formatters.date(date),
                  placeholder: date == null,
                  icon: Icons.calendar_today_outlined,
                  onTap: () => controller.pickSaleDate(context),
                ),
              if (sold) ...[
                VaultTextField(
                  label: 'Sale price',
                  controller: controller.salePrice,
                  validator: Validators.optionalAmount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                VaultTextField(
                  label: 'Buyer details',
                  hint: 'Optional · keep only if necessary',
                  controller: controller.buyerNote,
                ),
              ],
            ],
          );
        }),
      ],
    );
  }
}
