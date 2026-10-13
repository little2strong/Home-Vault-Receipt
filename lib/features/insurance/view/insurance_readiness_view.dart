import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/vault_blocks.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_header.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/insurance_controller.dart';

/// 75 · Insurance readiness
class InsuranceReadinessView extends GetView<InsuranceController> {
  const InsuranceReadinessView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      CardTone tone(int n) => n == 0 ? CardTone.plain : CardTone.warning;
      final photos = controller.highValueMissingPhotos;
      final serials = controller.missingSerials;
      final appraisals = controller.staleAppraisals;
      return VaultPage(
        header: VaultHeader.back(
          menu: [
            VaultMenuAction('Build inventory report', controller.openReport),
            VaultMenuAction('Start a claim', controller.openClaim),
            VaultMenuAction('Valuation insights', controller.openValuation),
          ],
        ),
        title: 'Have the evidence\nready.',
        subtitle: 'A documentation guide, not insurance approval.',
        roadmap: true,
        actions: [
          VaultButton(
            label: 'Review evidence gaps',
            onPressed: controller.reviewGaps,
          ),
        ],
        children: [
          HeroCard(
            label: 'Documentation completeness',
            value: '${controller.completeness}%',
            caption: 'Based on evidence, not coverage.',
            large: true,
          ),
          InfoCard(
            title: 'High-value photos',
            subtitle: photos == 0
                ? 'Complete'
                : '${Formatters.count(photos, 'item')} missing photos',
            tone: tone(photos),
          ),
          InfoCard(
            title: 'Serial labels',
            subtitle: serials == 0
                ? 'Complete'
                : '${Formatters.count(serials, 'item')} missing numbers',
            tone: tone(serials),
          ),
          InfoCard(
            title: 'Appraisals',
            subtitle: appraisals == 0
                ? 'Up to date'
                : '${Formatters.count(appraisals, 'valuation')} out of date',
            tone: tone(appraisals),
          ),
          InfoCard(
            title: 'Inventory report',
            subtitle: 'Select evidence to share with your insurer',
            onTap: controller.openReport,
          ),
          InfoCard(
            title: 'Start a claim',
            subtitle: 'Bring the facts together',
            onTap: controller.openClaim,
          ),
        ],
      );
    });
  }
}
