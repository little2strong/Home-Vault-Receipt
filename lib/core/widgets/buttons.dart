import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';
import '../theme/vault_palette.dart';

enum ButtonKind { primary, secondary, danger, dark }

/// One primary action per screen, at the bottom, at least 52 pt tall.
class VaultButton extends StatelessWidget {
  const VaultButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.kind = ButtonKind.primary,
    this.expand = true,
  });

  const VaultButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = true,
  }) : kind = ButtonKind.secondary;

  const VaultButton.danger({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = true,
  }) : kind = ButtonKind.danger;

  const VaultButton.dark({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = true,
  }) : kind = ButtonKind.dark;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final ButtonKind kind;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (bg, fg, border) = switch (kind) {
      ButtonKind.primary => (p.primary, p.onPrimary, null),
      ButtonKind.secondary => (p.surface, p.ink, p.outline),
      ButtonKind.danger => (p.dangerInk, Colors.white, null),
      ButtonKind.dark => (p.hero, p.onHero, null),
    };
    final child = loading
        ? SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: fg,
              semanticsLabel: 'Working',
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
    return SizedBox(
      width: expand ? double.infinity : null,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          disabledBackgroundColor: bg.withValues(alpha: 0.5),
          disabledForegroundColor: fg.withValues(alpha: 0.8),
          minimumSize: const Size(64, AppSizes.buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
            side: border == null ? BorderSide.none : BorderSide(color: border),
          ),
        ),
        child: child,
      ),
    );
  }
}

/// Underlined green text link: "Not now", "Use a different email".
class LinkButton extends StatelessWidget {
  const LinkButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.underline = true,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool underline;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.palette.primary;
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: c,
        minimumSize: const Size(
          AppSizes.minTouchTarget,
          AppSizes.minTouchTarget,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 15,
          decoration: underline ? TextDecoration.underline : null,
          decorationColor: c,
        ),
      ),
    );
  }
}

/// The rounded square back / close / edit button from the design.
class SquareIconButton extends StatelessWidget {
  const SquareIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.dark = false,
  });

  const SquareIconButton.back({super.key, this.onPressed, this.dark = false})
    : icon = Icons.chevron_left_rounded,
      tooltip = 'Back';

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  /// Translucent on dark backgrounds (camera, viewer).
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: dark ? Colors.white.withValues(alpha: 0.14) : p.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(dark ? 99 : 14),
            side: dark ? BorderSide.none : BorderSide(color: p.outline),
          ),
          child: InkWell(
            customBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(dark ? 99 : 14),
            ),
            onTap: onPressed ?? () => Navigator.of(context).maybePop(),
            child: SizedBox.square(
              dimension: AppSizes.minTouchTarget + 2,
              child: Icon(
                icon,
                color: dark ? Colors.white : p.ink,
                size: icon == Icons.chevron_left_rounded ? 28 : 22,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
