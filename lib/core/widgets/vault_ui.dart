import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_sizes.dart';
import '../theme/vault_palette.dart';

/// White card, radius 16, hairline border.
class VaultCard extends StatelessWidget {
  const VaultCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSizes.md),
    this.onTap,
    this.color,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      side: BorderSide(color: borderColor ?? p.outline),
    );
    return Material(
      color: color ?? p.surface,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// A card holding rows separated by hairlines.
class ListCard extends StatelessWidget {
  const ListCard({super.key, required this.children, this.indent = 0});

  final List<Widget> children;

  /// Divider inset, so it starts after a leading icon.
  final double indent;

  @override
  Widget build(BuildContext context) {
    final rows = children.where((w) => w is! SizedBox).toList();
    return VaultCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: indent,
                color: context.palette.outline,
              ),
            rows[i],
          ],
        ],
      ),
    );
  }
}

/// Pale green rounded square holding an icon.
class IconTile extends StatelessWidget {
  const IconTile(
    this.icon, {
    super.key,
    this.size = 48,
    this.color,
    this.iconColor,
    this.semanticLabel,
  });

  final IconData icon;
  final double size;
  final Color? color;
  final Color? iconColor;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color ?? p.tonal,
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      child: Icon(
        icon,
        color: iconColor ?? p.primary,
        size: size * 0.48,
        semanticLabel: semanticLabel,
      ),
    );
  }
}

/// Icon, title, subtitle and a trailing amount or chevron.
class RowTile extends StatelessWidget {
  const RowTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.trailingText,
    this.onTap,
    this.link,
    this.onLink,
    this.chevron = false,
    this.dense = false,
    this.titleColor,
    this.highlight,
    this.badges = const [],
  });

  /// Small pills under the subtitle, e.g. `High value`.
  final List<Widget> badges;

  /// Search query whose matching words are marked in the title.
  final String? highlight;

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final String? trailingText;
  final VoidCallback? onTap;

  /// A small green link under the subtitle, e.g. "View receipt".
  final String? link;
  final VoidCallback? onLink;
  final bool chevron;
  final bool dense;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.textStyles;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSizes.md,
            vertical: dense ? 12 : 14,
          ),
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 14)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HighlightText(
                      title,
                      query: highlight,
                      style: t.titleMedium?.copyWith(
                        fontSize: 17,
                        color: titleColor,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      HighlightText(
                        subtitle!,
                        query: highlight,
                        style: t.bodyMedium?.copyWith(color: p.muted),
                      ),
                    ],
                    if (badges.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: badges,
                        ),
                      ),
                    if (link != null)
                      GestureDetector(
                        onTap: onLink,
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            link!,
                            style: t.labelLarge?.copyWith(
                              color: p.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (trailingText != null) ...[
                const SizedBox(width: 12),
                // Amounts shrink rather than push the name off screen at
                // large text sizes.
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      trailingText!,
                      style: t.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
              if (trailing != null) ...[
                const SizedBox(width: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 130),
                  child: trailing!,
                ),
              ],
              if (chevron) ...[
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded, color: p.muted),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Text with search matches marked in the design's amber, as in Search (07).
class HighlightText extends StatelessWidget {
  const HighlightText(this.text, {super.key, this.query, this.style});

  final String text;
  final String? query;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final terms = (query ?? '')
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (terms.isEmpty) return Text(text, style: style);
    final mark = TextStyle(
      backgroundColor: context.palette.warningSurface,
      color: style?.color ?? context.palette.ink,
    );
    final spans = <TextSpan>[];
    final word = RegExp(r'[A-Za-z0-9£€$]+');
    var last = 0;
    for (final m in word.allMatches(text)) {
      final w = m.group(0)!.toLowerCase();
      final term = terms.firstWhere((t) => w.startsWith(t), orElse: () => '');
      if (term.isEmpty) continue;
      spans
        ..add(TextSpan(text: text.substring(last, m.start)))
        ..add(
          TextSpan(
            text: text.substring(m.start, m.start + term.length),
            style: mark,
          ),
        );
      last = m.start + term.length;
    }
    spans.add(TextSpan(text: text.substring(last)));
    return Text.rich(TextSpan(style: style, children: spans));
  }
}

/// Label on the left, value on the right: the Item and Receipt detail rows.
class DetailRow extends StatelessWidget {
  const DetailRow(
    this.label,
    this.value, {
    super.key,
    this.valueColor,
    this.onTap,
    this.muted = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final VoidCallback? onTap;

  /// "Not stated" values are shown muted, never bold.
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.textStyles;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: 15,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              flex: value.isEmpty ? 10 : 4,
              child: Text(label, style: t.bodyLarge?.copyWith(color: p.muted)),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: value.isEmpty ? 1 : 6,
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: t.bodyLarge?.copyWith(
                  fontWeight: muted ? FontWeight.w400 : FontWeight.w700,
                  color: muted ? p.muted : (valueColor ?? p.ink),
                ),
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded, size: 20, color: p.muted),
            ],
          ],
        ),
      ),
    );
  }
}

/// `ITEMS`, `RECEIPTS`, `WORTH DOING NOW`.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                text.toUpperCase(),
                style: context.textStyles.labelLarge?.copyWith(
                  color: context.palette.muted,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// `Expiring soon` + `All warranties` link.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: context.textStyles.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          if (action != null)
            Flexible(
              child: InkWell(
                onTap: onAction,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    action!,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: context.palette.primary,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                      decorationColor: context.palette.primary,
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

enum PillTone { neutral, green, amber, grey, red }

/// Small tag such as `Physical`, `Active`, `High value`, `41 days`.
class Pill extends StatelessWidget {
  const Pill(this.label, {super.key, this.tone = PillTone.neutral, this.icon});

  final String label;
  final PillTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (bg, fg, border) = switch (tone) {
      PillTone.neutral => (p.background, p.ink, p.outline),
      PillTone.green => (p.tonal, p.primary, p.tonal),
      PillTone.amber => (p.warningSurface, p.warningInk, p.warningSurface),
      PillTone.grey => (p.background, p.muted, p.outline),
      PillTone.red => (p.dangerSurface, p.dangerInk, p.dangerSurface),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Selectable chip: dark green when selected, white with border otherwise.
class ChoicePill extends StatelessWidget {
  const ChoicePill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.rounded = false,
    this.count,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Fully rounded (filter chips) or 12-radius (tag choices).
  final bool rounded;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final radius = BorderRadius.circular(rounded ? 99 : 12);
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? p.hero : p.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: selected ? p.hero : p.outline),
        ),
        child: InkWell(
          customBorder: RoundedRectangleBorder(borderRadius: radius),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppSizes.minTouchTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: selected ? p.onHero : p.ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  if (count != null)
                    Text(
                      '$count',
                      style: TextStyle(
                        color: selected ? p.onHero : p.ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A wrapped group of [ChoicePill]s for one enum.
class ChoiceGroup<T> extends StatelessWidget {
  const ChoiceGroup({
    super.key,
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelected,
    this.rounded = false,
  });

  final List<T> values;
  final T? selected;
  final String Function(T) label;
  final ValueChanged<T> onSelected;
  final bool rounded;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final v in values)
          ChoicePill(
            label: label(v),
            selected: v == selected,
            rounded: rounded,
            onTap: () => onSelected(v),
          ),
      ],
    );
  }
}

/// Pale green note with an icon: "Shown as an estimate…".
class InfoNote extends StatelessWidget {
  const InfoNote(
    this.text, {
    super.key,
    this.icon = Icons.info_outline_rounded,
    this.title,
    this.trailing,
    this.warning = false,
    this.onTap,
  });

  final String text;
  final IconData? icon;
  final String? title;
  final Widget? trailing;
  final bool warning;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final bg = warning ? p.warningSurface : p.tonal;
    final fg = warning ? p.warningInk : p.primary;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Row(
            crossAxisAlignment: title == null
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                Icon(icon, color: fg, size: 22),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          title!,
                          style: context.textStyles.titleMedium,
                        ),
                      ),
                    Text(
                      text,
                      style: context.textStyles.bodyMedium?.copyWith(
                        color: warning ? p.ink : p.ink,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

/// Dark green summary card: "Spent in last 30 days".
class HeroCard extends StatelessWidget {
  const HeroCard({super.key, required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.palette.hero,
      borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: DefaultTextStyle.merge(
            style: TextStyle(color: context.palette.onHero),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Field label above its input.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 16),
    child: Text(
      text,
      style: context.textStyles.labelLarge?.copyWith(
        color: context.palette.muted,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.keyboardType,
    this.onChanged,
    this.warning,
    this.bold = false,
    this.textCapitalization = TextCapitalization.sentences,
    this.inputFormatters,
    this.autofillHints,
    this.validator,
    this.maxLines = 1,
    this.prefix,
    this.obscureText = false,
    this.suffix,
    this.textInputAction,
    this.onSubmitted,
    this.error,
    this.prefixIcon,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  /// Amber outline and message: "Couldn't read this — add it if you can see it".
  final String? warning;
  final bool bold;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final FormFieldValidator<String>? validator;
  final int maxLines;
  final String? prefix;

  /// Hides the text, for passwords.
  final bool obscureText;
  final Widget? suffix;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  /// Red outline and message under the field, e.g. "Enter your email address."
  final String? error;
  final Widget? prefixIcon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final warn = warning != null;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizes.fieldRadius),
      borderSide: BorderSide(color: warn ? p.warningBorder : p.outline),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          validator: validator,
          maxLines: maxLines,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
          obscureText: obscureText,
          autocorrect: !obscureText,
          enableSuggestions: !obscureText,
          textInputAction: textInputAction,
          onFieldSubmitted: onSubmitted,
          autofillHints: autofillHints,
          style: TextStyle(
            fontSize: 18,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w400,
            color: p.ink,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefix,
            prefixIcon: prefixIcon,
            suffixIcon: suffix,
            errorText: error,
            errorMaxLines: 2,
            enabledBorder: warn ? border : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 18,
            ),
          ),
        ),
        if (warn)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 18,
                  color: p.warningInk,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    warning!,
                    style: TextStyle(
                      color: p.warningInk,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A tappable field that opens a picker: date, currency, room.
class PickerField extends StatelessWidget {
  const PickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.placeholder = 'Not stated',
    this.icon = Icons.expand_more_rounded,
    this.showLabel = true,
  });

  final String label;
  final String? value;
  final VoidCallback onTap;
  final String placeholder;
  final IconData? icon;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel) FieldLabel(label),
        Semantics(
          button: true,
          label: '$label: ${value ?? placeholder}',
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 18,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        value ?? placeholder,
                        style: TextStyle(
                          fontSize: 18,
                          color: value == null ? p.muted : p.ink,
                        ),
                      ),
                    ),
                    if (icon != null) Icon(icon, color: p.muted),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Switch row: "Same for all items", "In my home".
class SwitchRow extends StatelessWidget {
  const SwitchRow({
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
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.textStyles.titleMedium),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: context.textStyles.bodyMedium?.copyWith(
                          color: context.palette.muted,
                        ),
                      ),
                  ],
                ),
              ),
              Switch(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}

/// Two-segment progress bar for the review steps.
class StepBar extends StatelessWidget {
  const StepBar({super.key, required this.step, this.steps = 2});

  final int step;
  final int steps;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      label: 'Step $step of $steps',
      child: Row(
        children: [
          for (var i = 1; i <= steps; i++) ...[
            if (i > 1) const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 5,
                decoration: BoxDecoration(
                  color: i <= step ? p.primary : p.outline,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// `− 1 +` counter used in Home setup and quantity splits.
class Counter extends StatelessWidget {
  const Counter({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 20,
    this.label = '',
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Widget button(IconData icon, String tip, int next, bool enabled) =>
        Semantics(
          button: true,
          label: '$tip $label',
          child: Material(
            color: p.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: p.outline),
            ),
            child: InkWell(
              customBorder: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onTap: enabled ? () => onChanged(next) : null,
              child: SizedBox.square(
                dimension: AppSizes.minTouchTarget,
                child: Icon(icon, size: 20, color: enabled ? p.ink : p.outline),
              ),
            ),
          ),
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        button(Icons.remove_rounded, 'Fewer', value - 1, value > min),
        SizedBox(
          width: 40,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: value == 0 ? p.muted : p.ink,
            ),
          ),
        ),
        button(Icons.add_rounded, 'More', value + 1, value < max),
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 8),
      child: Column(
        children: [
          IconTile(icon, size: 72),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: context.textStyles.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: context.textStyles.bodyMedium?.copyWith(
              color: context.palette.muted,
            ),
          ),
          if (action != null) ...[const SizedBox(height: 20), action!],
        ],
      ),
    );
  }
}

/// Small stat card: "Last 30 days £612.40".
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.caption,
    this.tone,
    this.onTap,
  });

  final String label;
  final String value;
  final String? caption;
  final PillTone? tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (bg, fg) = switch (tone) {
      PillTone.amber => (p.warningSurface, p.warningInk),
      PillTone.green => (p.tonal, p.primary),
      _ => (p.surface, p.ink),
    };
    return VaultCard(
      color: bg,
      borderColor: tone == null ? null : bg,
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: tone == null ? p.muted : fg,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
          ),
          if (caption != null)
            Text(caption!, style: TextStyle(color: p.muted, fontSize: 12)),
        ],
      ),
    );
  }
}

/// Two cards per row whose height follows their content, so large text
/// never clips (unlike a fixed-aspect grid).
class TwoColumn extends StatelessWidget {
  const TwoColumn({super.key, required this.children, this.spacing = 14});

  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < children.length; i += 2) ...[
          if (i > 0) SizedBox(height: spacing),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: children[i]),
                SizedBox(width: spacing),
                Expanded(
                  child: i + 1 < children.length
                      ? children[i + 1]
                      : const SizedBox(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
