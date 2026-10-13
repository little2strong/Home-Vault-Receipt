import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/route_view.dart';
import '../../../core/widgets/vault_blocks.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_fields.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/review_controller.dart';

/// 25 · Edit extracted field (purchase date)
class EditDateView extends RouteView<ReviewController> {
  const EditDateView({super.key});

  @override
  Widget buildWith(BuildContext context, ReviewController controller) {
    return Obx(() {
      final ambiguous = controller.dateIsAmbiguous;
      final warning = ambiguous ? AppStrings.checkSource : null;
      final date = controller.pendingDate.value;
      final error = controller.pendingDateError;
      return VaultPage(
        title: 'Check the purchase\ndate.',
        subtitle: ambiguous
            ? 'The printed date is ambiguous.'
            : 'Confirm the date printed on the receipt.',
        actions: [
          VaultButton(label: 'Use this date', onPressed: controller.useDate),
        ],
        children: [
          VaultSelectField(
            label: 'Recognised text',
            value: controller.recognisedDate,
            warning: warning,
          ),
          VaultSelectField(
            label: 'Your purchase date',
            value: date == null ? 'Choose date' : Formatters.date(date),
            placeholder: date == null,
            warning: warning,
            icon: Icons.calendar_today_outlined,
            onTap: () => controller.pickPurchaseDate(context),
          ),
          if (ambiguous)
            VaultSelectField(
              label: 'Date interpretation',
              value: controller.dateOrder.value.label,
              warning: warning,
              onTap: () => controller.pickDateOrder(context),
            ),
          if (error != null && date != null)
            NoticeBanner(text: error, tone: NoticeTone.danger),
        ],
      );
    });
  }
}
