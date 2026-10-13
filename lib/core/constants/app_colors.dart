import 'package:flutter/material.dart';

/// Raw palette from the Home Vault design. Widgets read colours through
/// `context.palette` (see `VaultPalette`) so light and dark stay in sync.
abstract final class AppColors {
  static const background = Color(0xFFF4F5F0);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF173B35);
  static const muted = Color(0xFF5F6B67);
  static const primary = Color(0xFF1F6B52);
  static const hero = Color(0xFF173A34);
  static const tonal = Color(0xFFE4EDE6);
  static const outline = Color(0xFFDDE3DF);
  static const warningSurface = Color(0xFFFDEBD5);
  static const warningInk = Color(0xFF8A4B12);
  static const warningBorder = Color(0xFF9A6A3A);
  static const dangerSurface = Color(0xFFFBE7E4);
  static const dangerInk = Color(0xFFB3362B);
  static const illustration = Color(0xFFDDE7DF);

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
