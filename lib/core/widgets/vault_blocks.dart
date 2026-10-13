import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';
import '../theme/vault_palette.dart';

/// Dark summary card: `YOUR VAULT · 42 receipts, organised.`
class HeroCard extends StatelessWidget {
  const HeroCard({
    super.key,
    required this.label,
    required this.value,
    this.caption,
    this.large = false,
  });

  final String label;
  final String value;
  final String? caption;

  /// Large numeric value (receipt total, completeness score).
  final bool large;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.textStyles;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSizes.md),
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: p.hero,
        borderRadius: BorderRadius.circular(AppSizes.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: text.labelSmall?.copyWith(
              color: p.onHero.withValues(alpha: 0.85),
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            value,
            style: (large ? text.headlineLarge : text.titleLarge)?.copyWith(
              color: p.onHero,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 6),
            Text(
              caption!,
              style: text.bodySmall?.copyWith(
                color: p.onHero.withValues(alpha: 0.85),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum NoticeTone { info, warning, danger }

/// Coloured banner: `Draft preserved`, `Limit reached`, irreversible
/// action warnings.
class NoticeBanner extends StatelessWidget {
  const NoticeBanner({
    super.key,
    required this.text,
    this.tone = NoticeTone.info,
    this.detail,
  });

  final String text;
  final String? detail;
  final NoticeTone tone;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (background, foreground) = switch (tone) {
      NoticeTone.info => (p.tonal, p.onTonal),
      NoticeTone.warning => (p.warningSurface, p.warningInk),
      NoticeTone.danger => (p.dangerSurface, p.dangerInk),
    };

    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: context.textStyles.titleSmall?.copyWith(
                color: foreground,
                fontWeight: tone == NoticeTone.danger
                    ? FontWeight.w500
                    : FontWeight.w700,
              ),
            ),
            if (detail != null) ...[
              const SizedBox(height: 4),
              Text(
                detail!,
                style: context.textStyles.bodySmall?.copyWith(
                  color: foreground,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Tonal card with a progress bar: `Processing your document`.
class ProgressCard extends StatelessWidget {
  const ProgressCard({super.key, required this.title, this.value});

  final String title;

  /// 0–1, or null for indeterminate.
  final double? value;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.md),
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: p.tonal,
        borderRadius: BorderRadius.circular(AppSizes.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.textStyles.titleSmall),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 6,
              semanticsLabel: title,
            ),
          ),
        ],
      ),
    );
  }
}

/// Upper-case section label: `NEEDS YOUR ATTENTION` style headings are
/// sentence case in the design, month groups are upper case.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.upper = false});

  final String text;
  final bool upper;

  @override
  Widget build(BuildContext context) {
    final style = upper
        ? context.textStyles.labelSmall?.copyWith(
            color: context.palette.muted,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          )
        : context.textStyles.titleSmall;
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.sm, bottom: AppSizes.sm),
      child: Semantics(
        header: true,
        child: Text(upper ? text.toUpperCase() : text, style: style),
      ),
    );
  }
}

/// `01  Photograph or import` numbered step; also the timeline row
/// (`12 Sep  Purchased`).
class StepTile extends StatelessWidget {
  const StepTile({
    super.key,
    required this.badge,
    required this.title,
    this.detail,
  });

  final String badge;
  final String title;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            constraints: const BoxConstraints(minWidth: 44),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: p.tonal,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              badge,
              textAlign: TextAlign.center,
              style: context.textStyles.labelSmall?.copyWith(
                color: p.onTonal,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.textStyles.titleSmall),
                if (detail != null) ...[
                  const SizedBox(height: 4),
                  Text(detail!, style: context.textStyles.bodySmall),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tonal block with a document thumbnail: `Document preview · Original
/// stays attached`.
class DocumentPreviewCard extends StatelessWidget {
  const DocumentPreviewCard({
    super.key,
    this.title = 'Document preview',
    this.subtitle = 'Original stays attached',
    this.icon = Icons.description_outlined,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.md),
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: p.tonal,
        borderRadius: BorderRadius.circular(AppSizes.radius),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 86,
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(icon, color: p.primary),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.textStyles.titleSmall),
                const SizedBox(height: 6),
                Text(subtitle, style: context.textStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
