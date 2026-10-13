import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/vault_palette.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/message_view.dart';
import '../../../core/widgets/route_view.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_fields.dart';
import '../../../core/widgets/vault_header.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/review_controller.dart';

/// 23 · Review summary
class ReviewSummaryView extends RouteView<ReviewController> {
  const ReviewSummaryView({super.key});

  @override
  Widget buildWith(BuildContext context, ReviewController controller) {
    return Obx(() {
      final draft = controller.draft;
      if (draft == null) {
        return const VaultPage(
          body: MessageView(
            icon: Icons.inventory_2_outlined,
            title: 'This draft is no longer here',
            message: 'It may have been saved or discarded.',
          ),
        );
      }
      return VaultPage(
        header: VaultHeader.back(
          menu: [
            VaultMenuAction(
              'Discard draft',
              () => controller.discardDraft(context),
              destructive: true,
            ),
          ],
        ),
        title: 'Check the details.',
        subtitle: 'Check the details before saving.',
        actions: [
          VaultButton(
            label: 'Review products',
            onPressed: controller.continueToProducts,
          ),
        ],
        children: [
          Row(
            children: [
              controller.needsReview
                  ? const StatusChip(
                      label: 'Needs review',
                      tone: ChipTone.warning,
                    )
                  : const StatusChip(label: 'Checked'),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  'Tap a field to correct it',
                  style: context.textStyles.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Form(
            key: controller.formKey,
            child: Column(
              children: [
                VaultTextField(
                  label: 'Retailer',
                  controller: controller.retailerController,
                  validator: Validators.required,
                  textCapitalization: TextCapitalization.words,
                ),
                VaultSelectField(
                  label: 'Purchase date',
                  value: controller.purchaseDateLabel,
                  warning: controller.purchaseDateWarning,
                  icon: Icons.edit_calendar_outlined,
                  onTap: controller.openDate,
                ),
                VaultTextField(
                  label: 'Total (${draft.currency})',
                  controller: controller.totalController,
                  validator: Validators.amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                VaultSelectField(
                  label: 'Return date',
                  value: controller.returnDateLabel,
                  placeholder: draft.returnDeadline == null,
                  warning: controller.returnDateWarning,
                  onTap: controller.openReturnTerms,
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}
