import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import '../constants/app_strings.dart';
import '../theme/vault_palette.dart';

class VaultMenuAction {
  const VaultMenuAction(
    this.label,
    this.onSelected, {
    this.destructive = false,
  });

  final String label;
  final VoidCallback onSelected;
  final bool destructive;
}

/// The top bar from the mockups: `home vault` + bell on tab roots, and
/// `< Home Vault ···` on pushed screens.
class VaultHeader extends StatelessWidget {
  const VaultHeader.brand({super.key, this.showBell = true})
    : _brand = true,
      menu = const [],
      onBack = null;

  const VaultHeader.back({super.key, this.menu = const [], this.onBack})
    : _brand = false,
      showBell = false;

  final bool _brand;
  final bool showBell;
  final List<VaultMenuAction> menu;

  /// Overrides the default pop, e.g. to confirm discarding a draft.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            if (_brand) ...[
              const SizedBox(width: 12),
              Semantics(
                header: true,
                child: Text(
                  AppStrings.brand,
                  style: context.textStyles.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              if (showBell)
                IconButton(
                  tooltip: AppStrings.reminders,
                  onPressed: () => Get.toNamed(Routes.reminders),
                  icon: Icon(
                    Icons.notifications_none_rounded,
                    color: palette.primary,
                  ),
                ),
            ] else ...[
              IconButton(
                tooltip: AppStrings.back,
                onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                icon: Icon(Icons.chevron_left_rounded, color: palette.primary),
              ),
              Text(AppStrings.appName, style: context.textStyles.bodySmall),
              const Spacer(),
              if (menu.isNotEmpty)
                PopupMenuButton<VaultMenuAction>(
                  tooltip: AppStrings.moreActions,
                  icon: Icon(Icons.more_horiz_rounded, color: palette.ink),
                  onSelected: (action) => action.onSelected(),
                  itemBuilder: (_) => [
                    for (final action in menu)
                      PopupMenuItem(
                        value: action,
                        child: Text(
                          action.label,
                          style: TextStyle(
                            color: action.destructive
                                ? palette.dangerInk
                                : null,
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }
}
