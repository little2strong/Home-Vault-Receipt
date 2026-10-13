import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';
import '../theme/vault_palette.dart';

enum CardTone { plain, tonal, warning, danger }

/// The white rounded "title + supporting line" card used across the design.
class InfoCard extends StatelessWidget {
  const InfoCard({
    super.key,
    required this.title,
    this.subtitle,
    this.trailingText,
    this.trailing,
    this.leading,
    this.onTap,
    this.tone = CardTone.plain,
    this.semanticLabel,
  });

  final String title;
  final String? subtitle;

  /// Bold right-aligned value, e.g. an amount or `11 days`.
  final String? trailingText;
  final Widget? trailing;
  final Widget? leading;
  final VoidCallback? onTap;
  final CardTone tone;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (background, titleColor) = switch (tone) {
      CardTone.plain => (p.surface, p.ink),
      CardTone.tonal => (p.tonal, p.onTonal),
      CardTone.warning => (p.warningSurface, p.warningInk),
      CardTone.danger => (p.dangerSurface, p.dangerInk),
    };
    final text = context.textStyles;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.sm),
      child: Semantics(
        button: onTap != null,
        label: semanticLabel,
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(AppSizes.radius),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSizes.radius),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 58),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    if (leading != null) ...[
                      leading!,
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: text.titleSmall?.copyWith(color: titleColor),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              subtitle!,
                              style: text.bodySmall?.copyWith(
                                color: tone == CardTone.plain
                                    ? p.muted
                                    : titleColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (trailingText != null) ...[
                      const SizedBox(width: AppSizes.sm),
                      Text(
                        trailingText!,
                        style: text.titleSmall?.copyWith(color: titleColor),
                      ),
                    ],
                    if (trailing != null) ...[
                      const SizedBox(width: AppSizes.sm),
                      trailing!,
                    ] else if (onTap != null && trailingText == null)
                      Icon(Icons.chevron_right_rounded, color: p.muted),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ToggleCard extends StatelessWidget {
  const ToggleCard({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: InfoCard(
        title: title,
        subtitle: subtitle,
        onTap: () => onChanged(!value),
        trailing: Switch(value: value, onChanged: onChanged),
      ),
    );
  }
}

class CheckCard extends StatelessWidget {
  const CheckCard({
    super.key,
    required this.title,
    required this.checked,
    required this.onChanged,
    this.subtitle,
    this.onEdit,
  });

  final String title;
  final String? subtitle;
  final bool checked;
  final ValueChanged<bool> onChanged;

  /// Shows an edit affordance on the right when set.
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: title,
      subtitle: subtitle,
      onTap: () => onChanged(!checked),
      leading: Checkbox(
        value: checked,
        onChanged: (v) => onChanged(v ?? false),
      ),
      trailing: onEdit == null
          ? const SizedBox.shrink()
          : IconButton(
              tooltip: 'Edit $title',
              onPressed: onEdit,
              icon: Icon(Icons.edit_outlined, color: context.palette.primary),
            ),
    );
  }
}
