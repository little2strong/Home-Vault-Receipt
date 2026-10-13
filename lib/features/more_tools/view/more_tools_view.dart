import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/vault_blocks.dart';
import '../../../core/widgets/vault_page.dart';

/// 52 · More tools. The ownership roadmap, kept behind More so launch
/// navigation stays small.
class MoreToolsView extends StatelessWidget {
  const MoreToolsView({super.key});

  static const _groups = [
    (
      'Possessions',
      'Items, rooms and documents',
      [
        ('Inventory', 'Everything you own', Routes.inventory),
        ('Rooms', 'Organise by where things belong', Routes.rooms),
        ('Inbox', 'Drafts waiting for your review', Routes.inbox),
        ('Completeness', 'Documentation score', Routes.completeness),
      ],
    ),
    (
      'Protection',
      'Warranties and insurance evidence',
      [
        ('Warranties', 'Know what is covered', Routes.warranties),
        ('Maintenance', 'A little care, on time', Routes.maintenance),
        ('Recall alerts', 'Check official notices', Routes.recallAlert),
        (
          'Insurance readiness',
          'Have the evidence ready',
          Routes.insuranceReadiness,
        ),
        ('Valuation insights', 'Understand recorded value', Routes.valuation),
      ],
    ),
    (
      'Household',
      'Members and locations',
      [
        ('Households', 'A place for each home', Routes.households),
        (
          'Property records',
          'Appliances and furnishings',
          Routes.propertyInventory,
        ),
        ('Activity history', 'What changed, and when', Routes.activity),
        ('Moving', 'Boxes, labels and progress', Routes.moving),
      ],
    ),
    (
      'Life of an item',
      'Maintenance, moving and resale',
      [
        ('Collections', 'The things you collect', Routes.collections),
        ('Appraisals', 'Keep valuations current', Routes.appraisal),
        (
          'Email imports',
          'Bring receipts into your vault',
          Routes.emailImports,
        ),
        ('Retailer imports', 'Your purchase history', Routes.retailerImports),
        ('Assistant', 'Ask your vault', Routes.assistant),
        ('Plans', 'What comes after the pilot', Routes.plans),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return VaultPage(
      title: 'More from your vault.',
      subtitle: 'Ownership features expand on your receipts.',
      roadmap: true,
      children: [
        for (final (title, subtitle, tools) in _groups) ...[
          SectionLabel(title),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ),
          for (final (name, detail, route) in tools)
            InfoCard(
              title: name,
              subtitle: detail,
              onTap: () => Get.toNamed(route),
            ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
