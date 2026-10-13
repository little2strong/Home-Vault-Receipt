import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/vault_palette.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/vault_blocks.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/help_controller.dart';
import '../widgets/contact_support_sheet.dart';

/// 51 · Help & support
class HelpView extends GetView<HelpController> {
  const HelpView({super.key});

  static Future<void> contactSupport(BuildContext context) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => const ContactSupportSheet(),
      );

  void _showTopic(BuildContext context, HelpTopic topic) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.pagePadding,
            0,
            AppSizes.pagePadding,
            AppSizes.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(topic.title, style: sheet.textStyles.titleLarge),
              const SizedBox(height: AppSizes.md),
              for (final (i, step) in topic.steps.indexed)
                StepTile(badge: '0${i + 1}', title: step),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return VaultPage(
      title: 'A little help.',
      subtitle: 'Find an answer or contact support.',
      children: [
        for (final topic in HelpController.topics)
          InfoCard(
            title: topic.title,
            subtitle: topic.summary,
            onTap: () => _showTopic(context, topic),
          ),
        InfoCard(
          title: 'Contact support',
          subtitle: 'Describe the issue without sharing secrets',
          onTap: () => contactSupport(context),
        ),
        if (kDebugMode) ...[
          const SectionLabel('Testing tools · debug builds only'),
          Obx(
            () => ToggleCard(
              title: 'Simulate offline',
              subtitle: 'New saves wait in the offline queue',
              value: controller.isOffline,
              onChanged: controller.setOffline,
            ),
          ),
          Obx(
            () => ToggleCard(
              title: 'Interrupt next upload',
              subtitle: 'Shows the upload failure recovery',
              value: controller.failNextUpload,
              onChanged: controller.setFailNextUpload,
            ),
          ),
        ],
      ],
    );
  }
}
