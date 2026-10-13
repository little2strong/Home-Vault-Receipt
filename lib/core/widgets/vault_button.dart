import 'package:flutter/material.dart';

import '../theme/vault_palette.dart';

enum ButtonVariant { primary, secondary, danger }

class VaultButton extends StatelessWidget {
  const VaultButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.variant = ButtonVariant.primary,
  });

  const VaultButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  }) : variant = ButtonVariant.secondary;

  const VaultButton.danger({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  }) : variant = ButtonVariant.danger;

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final ButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (background, foreground) = switch (variant) {
      ButtonVariant.primary => (p.primary, p.onPrimary),
      ButtonVariant.secondary => (p.tonal, p.onTonal),
      ButtonVariant.danger => (p.dangerInk, p.surface),
    };

    return FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        disabledBackgroundColor: background.withValues(alpha: 0.45),
        disabledForegroundColor: foreground.withValues(alpha: 0.8),
      ),
      child: loading
          ? SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: foreground,
                semanticsLabel: 'Working',
              ),
            )
          : Text(label),
    );
  }
}
