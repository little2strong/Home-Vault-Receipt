import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';
import 'vault_palette.dart';

abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light, VaultPalette.light);
  static ThemeData get dark => _build(Brightness.dark, VaultPalette.dark);

  static ThemeData _build(Brightness brightness, VaultPalette p) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: p.primary,
          brightness: brightness,
        ).copyWith(
          primary: p.primary,
          onPrimary: p.onPrimary,
          surface: p.background,
          onSurface: p.ink,
          onSurfaceVariant: p.muted,
          outline: p.outline,
          outlineVariant: p.outline,
          secondaryContainer: p.tonal,
          onSecondaryContainer: p.onTonal,
          error: p.dangerInk,
        );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
    );
    final text = base.textTheme.apply(bodyColor: p.ink, displayColor: p.ink);
    final fieldRadius = BorderRadius.circular(AppSizes.fieldRadius);
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide(color: color, width: width),
        );

    return base.copyWith(
      scaffoldBackgroundColor: p.background,
      extensions: [p],
      textTheme: text.copyWith(
        headlineMedium: text.headlineMedium?.copyWith(
          fontSize: 28,
          height: 1.2,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
        headlineSmall: text.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
        ),
        titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        titleSmall: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        bodySmall: text.bodySmall?.copyWith(color: p.muted),
        labelMedium: text.labelMedium?.copyWith(
          color: p.muted,
          fontWeight: FontWeight.w700,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        foregroundColor: p.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        hintStyle: TextStyle(color: p.muted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: border(p.outline),
        enabledBorder: border(p.outline),
        disabledBorder: border(p.outline),
        focusedBorder: border(p.primary, 1.5),
        errorBorder: border(p.dangerInk),
        focusedErrorBorder: border(p.dangerInk, 1.5),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
          shape: buttonShape,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.primary,
          minimumSize: const Size(AppSizes.minTouchTarget, 40),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.primary,
          shape: buttonShape,
          side: BorderSide(color: p.outline),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? p.primary
              : p.muted.withValues(alpha: 0.7),
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? p.tonal : p.surface,
        ),
        checkColor: WidgetStatePropertyAll(p.primary),
        side: BorderSide(color: p.outline, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.surface,
        indicatorColor: p.tonal,
        height: 68,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? p.primary : p.muted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: states.contains(WidgetState.selected) ? p.primary : p.muted,
          ),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.primary,
        linearTrackColor: p.primary.withValues(alpha: 0.2),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dialogTheme: DialogThemeData(backgroundColor: p.surface),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.hero,
        contentTextStyle: TextStyle(color: p.onHero),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: DividerThemeData(color: p.outline, space: 1),
      listTileTheme: ListTileThemeData(iconColor: p.primary, textColor: p.ink),
    );
  }
}
