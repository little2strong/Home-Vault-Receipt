import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/vault_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/route_view.dart';
import '../../../core/widgets/vault_blocks.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/return_terms_controller.dart';

/// 27 · Return terms review
class ReturnTermsView extends RouteView<ReturnTermsController> {
  const ReturnTermsView({super.key});

  @override
  Widget buildWith(BuildContext context, ReturnTermsController controller) {
    return Obx(() {
      final wording = controller.wording;
      final chosen = controller.chosen.value;
      final error = controller.error;
      final reminder = controller.receipt?.reminderDaysBefore ?? const [7, 1];
      return VaultPage(
        title: 'A date with evidence.',
        subtitle: wording != null
            ? 'Confirm the deadline printed on your receipt.'
            : 'No return terms were recognised. Add a date only if you can '
                  'verify it.',
        actions: [
          VaultButton.secondary(
            label: 'Leave blank',
            onPressed: controller.leaveBlank,
          ),
          VaultButton(label: 'Confirm deadline', onPressed: controller.confirm),
        ],
        children: [
          InfoCard(
            title: 'Receipt wording',
            subtitle: wording ?? 'Not stated on this receipt.',
          ),
          InfoCard(
            title: controller.matchesReceipt
                ? 'Suggested deadline'
                : 'Your deadline',
            subtitle: chosen == null
                ? 'Choose a date'
                : Formatters.date(chosen),
            trailing: Icon(
              Icons.edit_calendar_outlined,
              color: context.palette.primary,
            ),
            onTap: () => controller.pickDeadline(context),
          ),
          InfoCard(
            title: 'Reminder',
            subtitle: reminder.isEmpty
                ? 'Off'
                : '${reminder.map((d) => d == 0 ? 'on the day' : Formatters.count(d, 'day')).join(' and ')} before',
          ),
          if (error != null) NoticeBanner(text: error, tone: NoticeTone.danger),
          const SizedBox(height: 8),
          Text(AppStrings.statutoryRights, style: context.textStyles.bodySmall),
        ],
      );
    });
  }
}
