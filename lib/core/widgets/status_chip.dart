import 'package:flutter/material.dart';

import '../theme/vault_palette.dart';

enum ChipTone { neutral, warning, danger }

/// Small pill such as `2 deadlines soon` or `Needs review`.
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.tone = ChipTone.neutral,
    this.onTap,
  });

  final String label;
  final ChipTone tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (background, foreground) = switch (tone) {
      ChipTone.neutral => (p.tonal, p.onTonal),
      ChipTone.warning => (p.warningSurface, p.warningInk),
      ChipTone.danger => (p.dangerSurface, p.dangerInk),
    };

    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: context.textStyles.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w800,
        ),
      ),
    );

    if (onTap == null) return chip;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Padding(
          // Pads the visual pill out to a comfortable touch target.
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: chip,
        ),
      ),
    );
  }
}

/// Filter pill: filled when selected, white otherwise.
class ChoicePill extends StatelessWidget {
  const ChoicePill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 40),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: selected ? p.primary : p.surface,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: selected ? p.primary : p.outline),
            ),
            child: Text(
              label,
              style: context.textStyles.labelMedium?.copyWith(
                color: selected ? p.onPrimary : p.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
