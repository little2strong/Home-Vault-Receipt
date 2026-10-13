import 'package:flutter/material.dart';

import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/route_view.dart';
import '../../../core/widgets/vault_blocks.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/save_result_controller.dart';

/// 38 · Upload failure
class UploadFailureView extends RouteView<SaveResultController> {
  const UploadFailureView({super.key});

  @override
  Widget buildWith(BuildContext context, SaveResultController controller) {
    return VaultPage(
      title: 'We could not finish.',
      subtitle: 'Your draft is still here. Try again when connected.',
      actions: [
        VaultButton.secondary(label: 'Later', onPressed: controller.done),
        VaultButton(label: 'Retry upload', onPressed: controller.retry),
      ],
      children: const [
        NoticeBanner(text: 'Draft preserved', tone: NoticeTone.warning),
        InfoCard(
          title: 'Original document upload',
          subtitle: 'Connection interrupted',
        ),
        InfoCard(title: 'Receipt details', subtitle: 'Draft preserved'),
        InfoCard(
          title: 'No duplicate record',
          subtitle: 'Retry continues the same save.',
        ),
      ],
    );
  }
}
