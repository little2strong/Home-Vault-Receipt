import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/repositories/settings_repository.dart';

class SplashController extends GetxController {
  SplashController({required this._auth, required this._settings});

  static const _splashDuration = Duration(milliseconds: 1200);

  final AuthRepository _auth;
  final SettingsRepository _settings;

  @override
  void onReady() {
    super.onReady();
    _navigateNext();
  }

  /// First launch → onboarding, signed out → sign in, unverified email →
  /// verification, otherwise straight into the vault.
  String get nextRoute {
    final user = _auth.currentUser.value;
    if (!_settings.onboardingSeen.value) return Routes.welcome;
    if (user == null) return Routes.signIn;
    if (!user.emailVerified) return Routes.verifyEmail;
    return Routes.shell;
  }

  Future<void> _navigateNext() async {
    await Future<void>.delayed(_splashDuration);
    Get.offAllNamed(nextRoute);
  }
}
