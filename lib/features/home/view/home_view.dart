import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/models/vault_models.dart';
import '../../../core/theme/vault_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/item_rows.dart';
import '../../../core/widgets/vault_ui.dart';
import '../../add/view/add_sheet.dart';
import '../../shell/controller/shell_controller.dart';
import '../controller/home_controller.dart';

/// 06 Home: search, expiring warranties, recent purchases, quick stats.
class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final store = controller.store;
    final t = context.textStyles;
    final p = context.palette;
    return Constrained(
      child: Obx(() {
        final profile = store.profile.value;
        final main = profile?.mainCurrency ?? 'GBP';
        final stats = store.stats.value;
        final expiring = store.expiringSoon;
        final recent = controller.recent;
        final pending = controller.saver.pending;
        final noPhoto = store.highValueWithoutPhoto;
        return RefreshIndicator(
          onRefresh: controller.refreshDrafts,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.pagePadding,
              AppSizes.lg,
              AppSizes.pagePadding,
              AppSizes.xl,
            ),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          controller.greeting,
                          style: t.titleMedium?.copyWith(
                            color: p.muted,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Semantics(
                          header: true,
                          child: Text(
                            profile?.firstName.isNotEmpty ?? false
                                ? profile!.firstName
                                : 'Welcome',
                            style: t.headlineLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: 'Account',
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Get.find<ShellController>().tab.value = 3,
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: p.hero,
                        child: Text(
                          profile?.initial ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _SearchBox(onTap: () => Get.toNamed(Routes.search)),
              const SizedBox(height: 18),
              HeroCard(
                onTap: () => Get.toNamed(Routes.spending),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Spent in last 30 days',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              moneyTotals(stats.last30Days, main: main),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Receipts',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${stats.receipts30}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (pending.isNotEmpty) ...[
                const SizedBox(height: 14),
                InfoNote(
                  pending.any((d) => d.lastError != null)
                      ? '${Formatters.count(pending.length, 'receipt')} not saved yet. Tap to retry.'
                      : '${Formatters.count(pending.length, 'receipt')} waiting for connection. '
                            "We'll save automatically.",
                  icon: Icons.cloud_upload_outlined,
                  warning: true,
                  onTap: () => Get.toNamed(Routes.pending),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: p.warningInk,
                  ),
                ),
              ],
              for (final d in controller.unfinished.take(1)) ...[
                const SizedBox(height: 14),
                InfoNote(
                  'You were checking ${d.shop ?? 'a receipt'}. Carry on where '
                  'you left off.',
                  icon: Icons.edit_note_rounded,
                  onTap: () => controller.resume(d),
                  trailing: Icon(Icons.chevron_right_rounded, color: p.primary),
                ),
              ],
              if (expiring.isNotEmpty) ...[
                SectionHeader(
                  'Expiring soon',
                  action: 'All warranties',
                  onAction: () => Get.find<ShellController>().tab.value = 2,
                ),
                for (final e in expiring.take(3))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ExpiringCard(entry: e),
                  ),
              ],
              if (noPhoto.isNotEmpty) ...[
                const SizedBox(height: 10),
                InfoNote(
                  noPhoto.length == 1
                      ? '${noPhoto.first.name} is marked high value but has no photo'
                      : '${noPhoto.length} high-value items have no photo',
                  icon: Icons.photo_camera_outlined,
                  warning: true,
                  onTap: () => Get.toNamed(Routes.photos(noPhoto.first.id)),
                ),
              ],
              SectionHeader(
                'Recent purchases',
                action: recent.isEmpty ? null : 'See all',
                onAction: () => Get.find<ShellController>().tab.value = 1,
              ),
              if (!store.loaded.value)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (recent.isEmpty)
                VaultCard(
                  child: EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'Add your first receipt',
                    message:
                        'Scan a paper receipt, choose a photo or import a PDF. '
                        'You check the details before anything is saved.',
                    action: VaultButton(
                      label: 'Add a receipt',
                      expand: false,
                      onPressed: AddSheet.open,
                    ),
                  ),
                )
              else
                ListCard(
                  indent: 82,
                  children: [
                    for (final r in recent)
                      switch (r) {
                        RecentItem(:final item) => ItemRow(item),
                        RecentReceipt(:final receipt) => ReceiptRow(
                          receipt,
                          titleOverride: '${receipt.displayShop} shop',
                        ),
                      },
                  ],
                ),
            ],
          ),
        );
      }),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      label: 'Search items, shops, rooms',
      excludeSemantics: true,
      child: Material(
        color: p.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.fieldRadius),
          side: BorderSide(color: p.outline),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.fieldRadius),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: Row(
              children: [
                Icon(Icons.search_rounded, color: p.muted),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Search items, shops, rooms',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: p.muted, fontSize: 17),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpiringCard extends StatelessWidget {
  const _ExpiringCard({required this.entry});

  final Object entry;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final today = DateTime.now();
    final (title, line, onTap) = switch (entry) {
      Warranty w => (
        w.itemName ?? 'Warranty',
        'Warranty ends ${Formatters.medium(w.endDate)} · '
            '${Formatters.daysRemaining(w.daysLeft(today))}',
        () => Get.toNamed(Routes.item(w.itemId)),
      ),
      ReturnDeadline r => (
        r.label ?? r.shop ?? 'Return',
        'Last day to return ${Formatters.medium(r.deadline)} · '
            '${Formatters.daysRemaining(r.daysLeft(today))}',
        () => Get.toNamed(Routes.receipt(r.receiptId)),
      ),
      _ => ('', '', () {}),
    };
    return Material(
      color: p.warningSurface,
      borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(
                entry is Warranty
                    ? Icons.gpp_maybe_outlined
                    : Icons.assignment_return_outlined,
                color: p.warningInk,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.textStyles.titleMedium),
                    Text(
                      line,
                      style: TextStyle(
                        color: p.warningInk,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: p.warningInk),
            ],
          ),
        ),
      ),
    );
  }
}
