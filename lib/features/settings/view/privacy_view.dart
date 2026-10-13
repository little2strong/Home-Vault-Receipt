import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/vault_palette.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/vault_page.dart';

/// 47 · Privacy controls. Navigation only, so no controller.
class PrivacyView extends StatelessWidget {
  const PrivacyView({super.key});

  static const _policy = [
    (
      'What we keep',
      'Receipt details you confirm, and the originals you attach.',
    ),
    (
      'Where it lives',
      'On this device first, then in your private cloud vault.',
    ),
    (
      'Who can see it',
      'Only you. Nothing is shared unless you create an export.',
    ),
    ('Your choices', 'Export everything at any time, or delete your account.'),
  ];

  void _showPolicy(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheet) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(
            AppSizes.pagePadding,
            0,
            AppSizes.pagePadding,
            AppSizes.lg,
          ),
          children: [
            Text('Privacy in brief', style: sheet.textStyles.titleLarge),
            const SizedBox(height: AppSizes.md),
            for (final (title, body) in _policy)
              InfoCard(title: title, subtitle: body),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return VaultPage(
      title: 'Your data belongs\nto you.',
      subtitle: 'Choose what to keep, share or remove.',
      children: [
        InfoCard(
          title: 'Export my vault',
          subtitle: 'Records and original documents',
          onTap: () => Get.toNamed(Routes.exportData),
        ),
        InfoCard(
          title: 'Connected services',
          subtitle: 'None connected · imports are on the roadmap',
          onTap: () => Get.toNamed(Routes.emailImports),
        ),
        InfoCard(
          title: 'Delete account',
          subtitle: 'Remove live records and documents',
          tone: CardTone.danger,
          onTap: () => Get.toNamed(Routes.deleteAccount),
        ),
        InfoCard(
          title: 'Privacy policy',
          subtitle: 'How your information is handled',
          onTap: () => _showPolicy(context),
        ),
      ],
    );
  }
}
