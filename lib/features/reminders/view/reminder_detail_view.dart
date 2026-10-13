import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/vault_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/message_view.dart';
import '../../../core/widgets/route_view.dart';
import '../../../core/widgets/vault_blocks.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_header.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/reminder_detail_controller.dart';

/// 42 · Reminder detail
class ReminderDetailView extends RouteView<ReminderDetailController> {
  const ReminderDetailView({super.key});

  @override
  Widget buildWith(BuildContext context, ReminderDetailController controller) {
    return Obx(() {
      final r = controller.receipt;
      final deadline = r?.returnDeadline;
      if (r == null || deadline == null) {
        return const VaultPage(
          body: MessageView(
            icon: Icons.event_busy_outlined,
            title: 'No return deadline',
            message: 'This receipt has no confirmed deadline.',
          ),
        );
      }
      final note = controller.skippedNote;
      return VaultPage(
        header: VaultHeader.back(
          menu: [
            VaultMenuAction('Change deadline', controller.changeDeadline),
            VaultMenuAction(
              'Remove deadline',
              controller.removeDeadline,
              destructive: true,
            ),
          ],
        ),
        title: controller.title,
        subtitle: 'Deadline: ${Formatters.date(deadline)}',
        actions: [
          VaultButton(
            label: 'Save reminder',
            loading: controller.isSaving.value,
            onPressed: controller.save,
          ),
        ],
        children: [
          InfoCard(
            title: 'Source',
            subtitle: r.deadlineSource?.label ?? 'Confirmed by you',
          ),
          InfoCard(
            title: 'Notify me',
            subtitle: ReminderDetailController.describe(controller.daysBefore),
            onTap: () => controller.pickSchedule(context),
          ),
          InfoCard(
            title: 'Delivery time',
            subtitle:
                '${Formatters.time(controller.minutes.value)} · '
                '${controller.timeZone}',
            onTap: () => controller.pickTime(context),
          ),
          if (note != null) NoticeBanner(text: note, tone: NoticeTone.warning),
          const SizedBox(height: 8),
          Text(AppStrings.statutoryRights, style: context.textStyles.bodySmall),
        ],
      );
    });
  }
}
