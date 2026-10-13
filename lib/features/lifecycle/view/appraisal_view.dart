import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/vault_blocks.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_fields.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/collections_controller.dart';

/// 94 · Appraisal
class AppraisalView extends GetView<CollectionsController> {
  const AppraisalView({super.key});

  @override
  Widget build(BuildContext context) {
    return VaultPage(
      title: 'Keep valuations\ncurrent.',
      subtitle: 'An appraisal is evidence, not a live market price.',
      roadmap: true,
      actions: [
        VaultButton(
          label: 'Save appraisal',
          onPressed: controller.saveAppraisal,
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
                  value: controller.appraisalItem.value ?? 'Choose item',
                  placeholder: controller.appraisalItem.value == null,
                  onTap: () => controller.pickItem(context),
                ),
                VaultTextField(
                  label: 'Appraiser',
                  hint: 'e.g. Example jeweller',
                  controller: controller.appraiserController,
                  validator: Validators.required,
                ),
                VaultTextField(
                  label: 'Valuation',
                  controller: controller.valueController,
                  validator: Validators.amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                VaultSelectField(
                  label: 'Appraisal date',
                  value: Formatters.date(
                    controller.appraisalDate.value ?? DateTime.now(),
                  ),
                  icon: Icons.calendar_today_outlined,
                  onTap: () => controller.pickAppraisalDate(context),
                ),
                ToggleCard(
                  title: 'Certificate',
                  subtitle: controller.certificateAttached.value
                      ? 'PDF attached'
                      : 'Not attached',
                  value: controller.certificateAttached.value,
                  onChanged: (v) => controller.certificateAttached.value = v,
                ),
              ],
            ),
          ),
        ),
        Obx(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (controller.appraisals.isNotEmpty)
                const SectionLabel('Saved appraisals'),
              for (final a in controller.appraisals)
                InfoCard(
                  title: a.item,
                  subtitle:
                      '${a.appraiser} · ${Formatters.date(a.date)}'
                      '${controller.isStale(a) ? ' · out of date' : ''}',
                  trailingText: Money.formatWhole(a.value),
                  tone: controller.isStale(a)
                      ? CardTone.warning
                      : CardTone.plain,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
