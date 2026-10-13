import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/account_security_controller.dart';

/// 45 · Account security
class AccountSecurityView extends GetView<AccountSecurityController> {
  const AccountSecurityView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = controller.user;
      final verified = user?.emailVerified ?? false;
      return VaultPage(
        title: 'Account & security',
        subtitle: 'Manage how you access your vault.',
        children: [
          InfoCard(
            title: 'Name',
            subtitle: user?.displayName ?? '',
            onTap: () => controller.editName(context),
          ),
          InfoCard(
            title: 'Email',
            subtitle:
                '${user?.email ?? ''} · ${verified ? 'verified' : 'not verified'}',
            tone: verified ? CardTone.plain : CardTone.warning,
            onTap: verified ? null : controller.verifyEmail,
          ),
          InfoCard(title: 'Sign-in methods', subtitle: controller.methodsLabel),
          ToggleCard(
            title: 'App lock',
            subtitle: 'Ask for Face ID or device passcode on open',
            value: controller.appLock,
            onChanged: controller.setAppLock,
          ),
          InfoCard(
            title: 'Signed-in devices',
            subtitle: Formatters.count(controller.devices.length, 'device'),
            onTap: controller.openDevices,
          ),
          if (controller.hasPassword)
            InfoCard(
              title: 'Password',
              subtitle: 'Change password by email link',
              onTap: controller.changePassword,
            ),
        ],
      );
    });
  }
}
