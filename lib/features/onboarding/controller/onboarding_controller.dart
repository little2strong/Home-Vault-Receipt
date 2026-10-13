import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/repositories/settings_repository.dart';

class OnboardingController extends GetxController {
  OnboardingController({required this._settings});

  final SettingsRepository _settings;

  void showHowItWorks() => Get.toNamed(Routes.howItWorks);

  Future<void> finish() async {
    await _settings.completeOnboarding();
    Get.offAllNamed(Routes.createAccount);
  }

  Future<void> skipToSignIn() async {
    await _settings.completeOnboarding();
    Get.offAllNamed(Routes.signIn);
  }
}
