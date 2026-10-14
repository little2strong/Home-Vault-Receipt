import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/data/vault_repository.dart';
import '../../../core/data/vault_store.dart';
import '../../../core/services/app_config.dart';
import '../../../core/theme/vault_palette.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/vault_ui.dart';
import '../../start/controller/start_controllers.dart';

/// 32 Account: spending for 30 days / 1 year / lifetime, and the menu.
class AccountView extends StatelessWidget {
  const AccountView({super.key});

  @override
  Widget build(BuildContext context) {
    final store = Get.find<VaultStore>();
    final t = context.textStyles;
    final p = context.palette;
    return Constrained(
      child: Obx(() {
        final profile = store.profile.value;
        final user = store.user.value;
        final main = profile?.mainCurrency ?? 'GBP';
        final s = store.stats.value;
        String total(Map<String, int> m) => money(m[main] ?? 0, main);
        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.pagePadding,
            AppSizes.lg,
            AppSizes.pagePadding,
            AppSizes.xl,
          ),
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 38,
                  backgroundColor: p.hero,
                  child: Text(
                    profile?.initial ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile?.displayName ??
                            user?.displayName ??
                            'Your account',
                        style: t.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (user?.email != null)
                        Text(
                          user!.email!,
                          style: TextStyle(color: p.muted, fontSize: 16),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Change name',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () async {
                    final name = await Pickers.text(
                      context,
                      title: 'Your name',
                      initial: profile?.displayName,
                      caps: TextCapitalization.words,
                    );
                    if (name != null && name.trim().isNotEmpty) {
                      await Get.find<VaultRepository>().updateProfile({
                        'displayName': name.trim(),
                      });
                    }
                  },
                ),
              ],
            ),
            SectionLabel('Spending · $main'),
            Row(
              children: [
                for (final (label, m) in [
                  ('Last 30 days', s.last30Days),
                  ('Last year', s.last365Days),
                  ('Lifetime', s.lifetime),
                ]) ...[
                  Expanded(
                    child: StatTile(
                      label: label,
                      value: total(m),
                      onTap: () =>
                          Get.toNamed(Routes.spending, arguments: label),
                    ),
                  ),
                  if (label != 'Lifetime') const SizedBox(width: 10),
                ],
              ],
            ),
            const SizedBox(height: 18),
            ListCard(
              indent: 82,
              children: [
                for (final (icon, label, route) in [
                  (
                    Icons.meeting_room_outlined,
                    'Home inventory and rooms',
                    Routes.rooms,
                  ),
                  (Icons.directions_car_outlined, 'Cars', Routes.cars),
                  (Icons.download_rounded, 'Download lists', Routes.export),
                  (
                    Icons.settings_outlined,
                    'Settings and privacy',
                    Routes.settings,
                  ),
                  (Icons.help_outline_rounded, 'Help', Routes.help),
                ])
                  RowTile(
                    leading: IconTile(icon),
                    title: label,
                    chevron: true,
                    onTap: () => Get.toNamed(route),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            VaultButton.secondary(
              label: 'Sign out',
              icon: Icons.logout_rounded,
              onPressed: () => confirmSignOut(context),
            ),
            const SizedBox(height: 16),
            Text(
              'Also on the web at ${AppConfig.webDomain} — same account.',
              textAlign: TextAlign.center,
              style: TextStyle(color: p.muted),
            ),
          ],
        );
      }),
    );
  }
}
