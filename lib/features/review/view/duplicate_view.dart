import 'package:flutter/material.dart';

import '../../../core/models/receipt_model.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/route_view.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/review_controller.dart';

/// 28 · Duplicate receipt
class DuplicateView extends RouteView<ReviewController> {
  const DuplicateView({super.key});

  String _line(Receipt r) =>
      '${r.retailer} · ${Formatters.shortDate(r.purchaseDate)} · '
      '${Money.format(r.total, currency: r.currency)}';

  @override
  Widget buildWith(BuildContext context, ReviewController controller) {
    final draft = controller.draft;
    final existing = controller.duplicateOf;
    return VaultPage(
      title: 'Already in your vault?',
      subtitle: 'This looks similar to a saved receipt.',
      actions: [
        VaultButton(label: 'Open existing', onPressed: controller.openExisting),
      ],
      children: [
        if (draft != null) InfoCard(title: 'New scan', subtitle: _line(draft)),
        if (existing != null)
          InfoCard(title: 'Existing record', subtitle: _line(existing)),
        const InfoCard(
          title: 'What would you like to do?',
          subtitle: 'Open existing or save as a separate purchase.',
        ),
        InfoCard(
          title: 'Save as a separate record',
          tone: CardTone.tonal,
          onTap: controller.saveSeparately,
        ),
      ],
    );
  }
}
