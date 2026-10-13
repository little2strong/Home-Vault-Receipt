import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/reminders_controller.dart';

/// 41 · Return reminders
class RemindersView extends GetView<RemindersController> {
  const RemindersView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final open = controller.open;
      return VaultPage(
        title: 'Keep your options\nopen.',
        subtitle: 'Deadlines confirmed from your records.',
        children: [
          if (!controller.remindersOn)
            InfoCard(
              title: 'Return reminders are off',
              subtitle: 'Turn them on in notification settings.',
              tone: CardTone.warning,
              onTap: controller.openNotificationSettings,
            ),
          if (open.isEmpty)
            const InfoCard(
              title: 'No open return deadlines',
              subtitle: 'Confirmed deadlines appear here, soonest first.',
            ),
          for (final r in open)
            InfoCard(
              title: controller.titleFor(r),
              subtitle: controller.subtitleFor(r),
              onTap: () => controller.openReminder(r),
            ),
          InfoCard(
            title: 'No deadline on receipt?',
            subtitle: 'Add a verified date yourself.',
            onTap: () => controller.addVerifiedDate(context),
          ),
        ],
      );
    });
  }
}
