import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/vault_palette.dart';
import '../controller/splash_controller.dart';
import '../widgets/splash_logo.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.hero,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SplashLogo(),
            const SizedBox(height: AppSizes.lg),
            Text(
              AppStrings.brand,
              style: context.textStyles.headlineSmall?.copyWith(
                color: p.onHero,
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              AppStrings.tagline,
              style: context.textStyles.bodyMedium?.copyWith(
                color: p.onHero.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
