import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/vault_blocks.dart';
import '../../../core/widgets/vault_header.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/settings_controller.dart';

/// 43 · Settings
class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = controller.user;
      final saved = controller.savedCount;
      final limit = controller.pilotLimit;
      return VaultPage(
        header: const VaultHeader.brand(),
        title: 'Your vault.\nYour control.',
        subtitle: '${user?.displayName ?? 'Guest'} · free pilot',
        children: [
          InfoCard(
            title: 'Account & security',
            subtitle: 'Sign-in methods and devices',
            onTap: () => controller.open(Routes.accountSecurity),
          ),
          InfoCard(
            title: 'Notifications',
            subtitle: controller.enabledReminderTypes == 0
                ? 'All reminders off'
                : 'Only reminders you choose',
            onTap: () => controller.open(Routes.notificationSettings),
          ),
          InfoCard(
            title: 'Privacy & data',
            subtitle: 'Export or delete your information',
            onTap: () => controller.open(Routes.privacy),
          ),
          InfoCard(
            title: 'Pilot usage',
            subtitle: '$saved / $limit receipts',
            trailing: SizedBox(
              width: 64,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: (saved / limit).clamp(0, 1),
                  minHeight: 6,
                  semanticsLabel: 'Pilot usage',
                ),
              ),
            ),
          ),
          InfoCard(
            title: 'Help & support',
            subtitle: 'Get help with your vault',
            onTap: () => controller.open(Routes.help),
          ),
          const SectionLabel('Coming later'),
          InfoCard(
            title: 'More from your vault',
            subtitle: 'Ownership tools on the roadmap',
            onTap: () => controller.open(Routes.moreTools),
          ),
          const SizedBox(height: 8),
          InfoCard(
            title: 'Sign out',
            tone: CardTone.danger,
            onTap: () => controller.signOut(context),
          ),
        ],
      );
    });
  }
}
