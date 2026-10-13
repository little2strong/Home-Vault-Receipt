import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/vault_blocks.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/protection_controller.dart';

/// 74 · Recall alert
class RecallAlertView extends GetView<ProtectionController> {
  const RecallAlertView({super.key});

  @override
  Widget build(BuildContext context) {
    return VaultPage(
      title: 'Check an official\nrecall.',
      subtitle: 'Illustrative safety alert, not a real recall.',
      roadmap: true,
      actions: [
        VaultButton(
          label: 'View official notice',
          onPressed: () => controller.viewOfficialNotice(context),
        ),
      ],
      children: const [
        NoticeBanner(
          text: 'Verify the official notice',
          tone: NoticeTone.warning,
        ),
        InfoCard(title: 'Affected product', subtitle: 'Sample appliance model'),
        InfoCard(
          title: 'Matching status',
          subtitle: 'Possible match · verify serial range',
        ),
        InfoCard(
          title: 'Action',
          subtitle: 'Read the official manufacturer notice',
        ),
      ],
    );
  }
}
