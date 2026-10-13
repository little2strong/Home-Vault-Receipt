import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Semantic colours from the design that Material's [ColorScheme] has no
/// slot for (hero card, warning and danger surfaces, illustration fill).
@immutable
class VaultPalette extends ThemeExtension<VaultPalette> {
  const VaultPalette({
    required this.background,
    required this.surface,
    required this.ink,
    required this.muted,
    required this.primary,
    required this.onPrimary,
    required this.hero,
    required this.onHero,
    required this.tonal,
    required this.onTonal,
    required this.outline,
    required this.warningSurface,
    required this.warningInk,
    required this.warningBorder,
    required this.dangerSurface,
    required this.dangerInk,
    required this.illustration,
  });

  static const light = VaultPalette(
    background: AppColors.background,
    surface: AppColors.surface,
    ink: AppColors.ink,
    muted: AppColors.muted,
    primary: AppColors.primary,
    onPrimary: Colors.white,
    hero: AppColors.hero,
    onHero: Colors.white,
    tonal: AppColors.tonal,
    onTonal: AppColors.primary,
    outline: AppColors.outline,
    warningSurface: AppColors.warningSurface,
    warningInk: AppColors.warningInk,
    warningBorder: AppColors.warningBorder,
    dangerSurface: AppColors.dangerSurface,
    dangerInk: AppColors.dangerInk,
    illustration: AppColors.illustration,
  );

  static const dark = VaultPalette(
    background: AppColors.darkBackground,
    surface: AppColors.darkSurface,
    ink: AppColors.darkInk,
    muted: AppColors.darkMuted,
    primary: AppColors.darkPrimary,
    onPrimary: AppColors.darkOnPrimary,
    hero: AppColors.darkHero,
    onHero: Colors.white,
    tonal: AppColors.darkTonal,
    onTonal: AppColors.darkOnTonal,
    outline: AppColors.darkOutline,
    warningSurface: AppColors.darkWarningSurface,
    warningInk: AppColors.darkWarningInk,
    warningBorder: AppColors.darkWarningBorder,
    dangerSurface: AppColors.darkDangerSurface,
    dangerInk: AppColors.darkDangerInk,
    illustration: AppColors.darkIllustration,
  );

  final Color background;
  final Color surface;
  final Color ink;
  final Color muted;
  final Color primary;
  final Color onPrimary;
  final Color hero;
  final Color onHero;
  final Color tonal;
  final Color onTonal;
  final Color outline;
  final Color warningSurface;
  final Color warningInk;
  final Color warningBorder;
  final Color dangerSurface;
  final Color dangerInk;
  final Color illustration;

  @override
  VaultPalette copyWith() => this;

  @override
  VaultPalette lerp(covariant VaultPalette? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return VaultPalette(
      background: c(background, other.background),
      surface: c(surface, other.surface),
      ink: c(ink, other.ink),
      muted: c(muted, other.muted),
      primary: c(primary, other.primary),
      onPrimary: c(onPrimary, other.onPrimary),
      hero: c(hero, other.hero),
      onHero: c(onHero, other.onHero),
      tonal: c(tonal, other.tonal),
      onTonal: c(onTonal, other.onTonal),
      outline: c(outline, other.outline),
      warningSurface: c(warningSurface, other.warningSurface),
      warningInk: c(warningInk, other.warningInk),
      warningBorder: c(warningBorder, other.warningBorder),
      dangerSurface: c(dangerSurface, other.dangerSurface),
      dangerInk: c(dangerInk, other.dangerInk),
      illustration: c(illustration, other.illustration),
    );
  }
}

extension VaultThemeContext on BuildContext {
  VaultPalette get palette => Theme.of(this).extension<VaultPalette>()!;
  TextTheme get textStyles => Theme.of(this).textTheme;
}
