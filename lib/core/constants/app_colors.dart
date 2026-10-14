import 'package:flutter/material.dart';

/// Visual tokens from the handbook. Widgets read colours through
/// `context.palette` (see `VaultPalette`) so light and dark stay in sync.
abstract final class AppColors {
  static const background = Color(0xFFF5F6F2);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF183A34);
  static const muted = Color(0xFF5D6C65);
  static const primary = Color(0xFF206951);
  static const hero = Color(0xFF183A34);
  static const tonal = Color(0xFFE7EFE7);
  static const outline = Color(0xFFDFE5DE);
  static const warningSurface = Color(0xFFFFF1D9);
  static const warningInk = Color(0xFF80501C);
  static const warningBorder = Color(0xFFE9C48E);
  static const dangerSurface = Color(0xFFFBE9E6);
  static const dangerInk = Color(0xFFA43434);
  static const illustration = Color(0xFFE7EFE7);
  static const camera = Color(0xFF0F1E1B);
  static const scrim = Color(0xFF7C8F89);

  static const darkBackground = Color(0xFF0F1513);
  static const darkSurface = Color(0xFF1A2320);
  static const darkInk = Color(0xFFE3EEE9);
  static const darkMuted = Color(0xFFA2AEA9);
  static const darkPrimary = Color(0xFF6CC4A2);
  static const darkOnPrimary = Color(0xFF05281C);
  static const darkHero = Color(0xFF21443C);
  static const darkTonal = Color(0xFF23362F);
  static const darkOnTonal = Color(0xFF9BD9BE);
  static const darkOutline = Color(0xFF2E3B37);
  static const darkWarningSurface = Color(0xFF3A2A17);
  static const darkWarningInk = Color(0xFFF3C58E);
  static const darkWarningBorder = Color(0xFFC58F55);
  static const darkDangerSurface = Color(0xFF3D1F1B);
  static const darkDangerInk = Color(0xFFF2A79E);
  static const darkIllustration = Color(0xFF26332F);
}
