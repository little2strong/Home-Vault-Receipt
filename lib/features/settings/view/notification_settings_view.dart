import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/notification_settings_controller.dart';

/// 44 · Notification settings
class NotificationSettingsView extends GetView<NotificationSettingsController> {
  const NotificationSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final p = controller.prefs.value;
      return VaultPage(
        title: 'Useful reminders.',
        subtitle: 'Choose what reaches you.',
        actions: [
          VaultButton(
            label: 'Save preferences',
            onPressed: controller.hasChanges ? controller.save : null,
          ),
        ],
        children: [
          ToggleCard(
            title: 'Return deadlines',
            subtitle: 'Before a confirmed return date',
            value: p.returnDeadlines,
            onChanged: (v) =>
                controller.change((x) => x.copyWith(returnDeadlines: v)),
          ),
          ToggleCard(
            title: 'Warranty expiry',
            subtitle: 'Before user-confirmed warranties end',
            value: p.warrantyExpiry,
            onChanged: (v) =>
                controller.change((x) => x.copyWith(warrantyExpiry: v)),
          ),
          ToggleCard(
            title: 'Maintenance',
            subtitle: 'Servicing you have scheduled',
            value: p.maintenance,
            onChanged: (v) =>
                controller.change((x) => x.copyWith(maintenance: v)),
          ),
          ToggleCard(
            title: 'New review items',
            subtitle: 'Drafts waiting for your check',
            value: p.newReviewItems,
            onChanged: (v) =>
                controller.change((x) => x.copyWith(newReviewItems: v)),
          ),
        ],
      );
    });
  }
}
