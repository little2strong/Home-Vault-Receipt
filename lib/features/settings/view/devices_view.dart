import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/account_security_controller.dart';

/// 46 · Device management
class DevicesView extends GetView<AccountSecurityController> {
  const DevicesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => VaultPage(
        title: 'Your devices',
        subtitle: 'Review sessions and revoke access.',
        actions: [
          VaultButton(
            label: 'Sign out other devices',
            onPressed: () => controller.revokeOthers(context),
          ),
        ],
        children: [
          for (final d in controller.devices)
            InfoCard(
              title: d.name,
              subtitle: d.isCurrent
                  ? 'Current device · ${d.location ?? 'here'}'
                  : 'Last active ${Formatters.shortDate(d.lastActive)}',
              onTap: d.isCurrent ? null : () => controller.revoke(context, d),
              trailing: d.isCurrent
                  ? null
                  : const Icon(Icons.logout_rounded, semanticLabel: 'Sign out'),
            ),
          InfoCard(
            title: 'Unrecognised device?',
            subtitle: 'Sign out the session and reset your password.',
            tone: CardTone.warning,
            onTap: () => controller.secureAccount(context),
          ),
        ],
      ),
    );
  }
}
