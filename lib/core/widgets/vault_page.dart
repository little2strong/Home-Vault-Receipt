import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../theme/vault_palette.dart';
import 'status_chip.dart';
import 'vault_header.dart';

/// The standard screen frame from the design: header, large headline,
/// supporting line, scrollable content and actions pinned to the bottom.
class VaultPage extends StatelessWidget {
  const VaultPage({
    super.key,
    this.header,
    this.title,
    this.subtitle,
    this.children = const [],
    this.body,
    this.actions = const [],
    this.roadmap = false,
  });

  /// Defaults to [VaultHeader.back].
  final Widget? header;
  final String? title;
  final String? subtitle;
  final List<Widget> children;

  /// Replaces the scrolling [children] list, for screens that manage their
  /// own layout (camera, chat).
  final Widget? body;

  /// Buttons pinned above the safe area; the last one is the primary action.
  final List<Widget> actions;

  /// Marks ownership-roadmap screens, which run on sample data.
  final bool roadmap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: actions.isEmpty,
        child: _Constrained(
          child: Column(
            children: [
              header ?? const VaultHeader.back(),
              Expanded(
                child:
                    body ??
                    ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSizes.pagePadding,
                        AppSizes.xs,
                        AppSizes.pagePadding,
                        AppSizes.lg,
                      ),
                      children: [..._intro(context), ...children],
                    ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: actions.isEmpty
          ? null
          : SafeArea(
              top: false,
              child: _Constrained(
                shrinkHeight: true,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.pagePadding,
                    AppSizes.sm,
                    AppSizes.pagePadding,
                    AppSizes.md,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < actions.length; i++) ...[
                        if (i > 0) const SizedBox(height: AppSizes.sm),
                        actions[i],
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  List<Widget> _intro(BuildContext context) => [
    if (title != null)
      Semantics(
        header: true,
        child: Text(title!, style: context.textStyles.headlineMedium),
      ),
    if (subtitle != null) ...[
      const SizedBox(height: AppSizes.sm),
      Text(
        subtitle!,
        style: context.textStyles.bodyMedium?.copyWith(
          color: context.palette.muted,
        ),
      ),
    ],
    if (roadmap) ...[
      const SizedBox(height: AppSizes.sm),
      const Align(
        alignment: Alignment.centerLeft,
        child: StatusChip(label: AppStrings.roadmapPreview),
      ),
    ],
    if (title != null || subtitle != null) const SizedBox(height: 20),
  ];
}

/// Pages that need the intro block above a custom [VaultPage.body].
class VaultPageIntro extends StatelessWidget {
  const VaultPageIntro({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.pagePadding,
        AppSizes.xs,
        AppSizes.pagePadding,
        AppSizes.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: context.textStyles.headlineMedium),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSizes.sm),
            Text(
              subtitle!,
              style: context.textStyles.bodyMedium?.copyWith(
                color: context.palette.muted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Constrained extends StatelessWidget {
  const _Constrained({required this.child, this.shrinkHeight = false});

  final Widget child;

  /// The bottom bar must wrap its buttons; an unconstrained [Align] there
  /// would take the whole screen height and squeeze the body to nothing.
  final bool shrinkHeight;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      heightFactor: shrinkHeight ? 1 : null,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.maxContentWidth),
        child: child,
      ),
    );
  }
}
