import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../start/controller/start_controllers.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/data/vault_store.dart';
import '../../../core/theme/vault_palette.dart';
import '../../../core/widgets/brand.dart';

/// Website frame: brand, top navigation and the account menu.
class WebScaffold extends StatelessWidget {
  const WebScaffold({super.key, required this.current, required this.child});

  final String current;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final store = Get.find<VaultStore>();
    final wide = MediaQuery.sizeOf(context).width > 820;
    final nav = [
      (Routes.webDashboard, 'Dashboard'),
      (Routes.webProducts, 'Products'),
      (Routes.webInventory, 'Home inventory'),
      (Routes.webDownloads, 'Downloads'),
    ];
    return Scaffold(
      backgroundColor: p.background,
      body: Column(
        children: [
          Container(
            color: p.surface,
            child: SafeArea(
              bottom: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppSizes.maxWebWidth,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Flexible(
                          child: InkWell(
                            onTap: () => Get.offAllNamed(Routes.webDashboard),
                            child: const BrandRow(),
                          ),
                        ),
                        const SizedBox(width: 24),
                        if (wide)
                          for (final (route, label) in nav)
                            _NavLink(
                              label: label,
                              route: route,
                              selected: current == route,
                            ),
                        const Spacer(),
                        if (!wide)
                          PopupMenuButton<String>(
                            tooltip: 'Menu',
                            icon: const Icon(Icons.menu_rounded),
                            onSelected: Get.offAllNamed,
                            itemBuilder: (_) => [
                              for (final (route, label) in nav)
                                PopupMenuItem(value: route, child: Text(label)),
                            ],
                          ),
                        Obx(
                          () => PopupMenuButton<String>(
                            tooltip: 'Account',
                            onSelected: (v) async {
                              if (v == 'out') {
                                await confirmSignOut(context);
                              } else if (v == 'delete') {
                                await Get.toNamed(Routes.webDeleteAccount);
                              } else if (v == 'privacy') {
                                await Get.toNamed(Routes.privacy);
                              }
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                enabled: false,
                                child: Text(store.user.value?.email ?? ''),
                              ),
                              const PopupMenuItem(
                                value: 'privacy',
                                child: Text('Privacy policy'),
                              ),
                              const PopupMenuItem(
                                value: 'out',
                                child: Text('Sign out'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text(
                                  'Delete account',
                                  style: TextStyle(color: p.dangerInk),
                                ),
                              ),
                            ],
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: p.hero,
                              child: Text(
                                store.profile.value?.initial ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Divider(height: 1, color: p.outline),
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppSizes.maxWebWidth,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 32, 16, 48),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  const _NavLink({
    required this.label,
    required this.route,
    required this.selected,
  });

  final String label;
  final String route;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Semantics(
        selected: selected,
        child: TextButton(
          onPressed: () => Get.offAllNamed(route),
          style: TextButton.styleFrom(
            backgroundColor: selected ? p.tonal : Colors.transparent,
            foregroundColor: selected ? p.ink : p.muted,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

/// Simple table for the website: header row and data rows.
class WebTable extends StatelessWidget {
  const WebTable({
    super.key,
    required this.columns,
    required this.rows,
    this.flex,
    this.onTap,
    this.alignEnd = const {},
  });

  final List<String> columns;
  final List<List<Widget>> rows;
  final List<int>? flex;
  final void Function(int index)? onTap;
  final Set<int> alignEnd;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Widget cell(int i, Widget child) => Expanded(
      flex: flex?[i] ?? 1,
      child: Align(
        alignment: alignEnd.contains(i)
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: child,
      ),
    );
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: p.background,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                for (var i = 0; i < columns.length; i++)
                  cell(
                    i,
                    Text(
                      columns[i].toUpperCase(),
                      style: TextStyle(
                        color: p.muted,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          for (var r = 0; r < rows.length; r++) ...[
            Divider(height: 1, color: p.outline),
            InkWell(
              onTap: onTap == null ? null : () => onTap!(r),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    for (var i = 0; i < rows[r].length; i++)
                      cell(i, rows[r][i]),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
