import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constants/app_sizes.dart';
import '../services/connectivity_service.dart';
import '../theme/vault_palette.dart';
import 'buttons.dart';

/// The standard screen frame: back square, large title, scrolling body and
/// actions pinned at the bottom within thumb reach.
class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    this.title,
    this.eyebrow,
    this.subtitle,
    this.children = const [],
    this.body,
    this.actions = const [],
    this.showBack = true,
    this.onBack,
    this.trailing,
    this.titleInHeader = true,
    this.padding,
    this.background,
  });

  final String? title;

  /// Small muted line above the title, e.g. `Samsung 55" QLED TV`.
  final String? eyebrow;
  final String? subtitle;
  final List<Widget> children;

  /// Replaces the scrolling [children] for screens with their own layout.
  final Widget? body;
  final List<Widget> actions;
  final bool showBack;
  final VoidCallback? onBack;
  final Widget? trailing;

  /// Title sits beside the back button (most pages) or below it.
  final bool titleInHeader;
  final EdgeInsets? padding;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final header = _header(context);
    return Scaffold(
      backgroundColor: background ?? p.background,
      body: SafeArea(
        bottom: actions.isEmpty,
        child: Column(
          children: [
            const OfflineBanner(),
            Expanded(
              child: Constrained(
                child:
                    body ??
                    ListView(
                      padding:
                          padding ??
                          const EdgeInsets.fromLTRB(
                            AppSizes.pagePadding,
                            AppSizes.md,
                            AppSizes.pagePadding,
                            AppSizes.lg,
                          ),
                      children: [?header, ...children],
                    ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: actions.isEmpty
          ? null
          : SafeArea(
              top: false,
              child: Constrained(
                shrink: true,
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
                        if (i > 0) const SizedBox(height: 12),
                        actions[i],
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget? _header(BuildContext context) {
    if (!showBack && title == null && trailing == null) return null;
    final titleBlock = title == null
        ? null
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null)
                Text(
                  eyebrow!,
                  style: context.textStyles.labelLarge?.copyWith(
                    color: context.palette.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              Semantics(
                header: true,
                child: Text(title!, style: context.textStyles.headlineMedium),
              ),
            ],
          );
    final subtitleBlock = subtitle == null
        ? null
        : Padding(
            padding: const EdgeInsets.only(top: AppSizes.sm),
            child: Text(
              subtitle!,
              style: context.textStyles.bodyLarge?.copyWith(
                color: context.palette.muted,
              ),
            ),
          );

    if (titleInHeader || !showBack) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (showBack) ...[
                  SquareIconButton.back(onPressed: onBack),
                  const SizedBox(width: AppSizes.md),
                ],
                if (titleBlock != null) Expanded(child: titleBlock),
                if (titleBlock == null) const Spacer(),
                ?trailing,
              ],
            ),
            ?subtitleBlock,
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SquareIconButton.back(onPressed: onBack),
              const Spacer(),
              ?trailing,
            ],
          ),
          const SizedBox(height: AppSizes.lg),
          ?titleBlock,
          ?subtitleBlock,
        ],
      ),
    );
  }
}

/// Centres content and caps its width on tablets and the web.
class Constrained extends StatelessWidget {
  const Constrained({
    super.key,
    required this.child,
    this.shrink = false,
    this.maxWidth = AppSizes.maxContentWidth,
  });

  final Widget child;
  final bool shrink;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      heightFactor: shrink ? 1 : null,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// "Waiting for connection" — trust is visible.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ConnectivityService>()) return const SizedBox();
    final online = Get.find<ConnectivityService>().online;
    return Obx(() {
      if (online.value) return const SizedBox.shrink();
      final p = context.palette;
      return Semantics(
        liveRegion: true,
        child: Container(
          width: double.infinity,
          color: p.warningSurface,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_rounded, size: 18, color: p.warningInk),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Waiting for connection · drafts are kept on this phone',
                  style: TextStyle(
                    color: p.warningInk,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
