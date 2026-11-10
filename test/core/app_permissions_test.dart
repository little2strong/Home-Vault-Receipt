import 'package:flutter_test/flutter_test.dart';
import 'package:home_vault_receipt/core/services/app_permissions.dart';

void main() {
  group('AppPermissions.deniedBy', () {
    test('reads image_picker refusals', () {
      expect(
        AppPermissions.deniedBy('photo_access_denied'),
        AppPermission.photos,
      );
      expect(
        AppPermissions.deniedBy('camera_access_denied'),
        AppPermission.camera,
      );
    });

    test('reads camera plugin refusals', () {
      for (final code in [
        'CameraAccessDenied',
        'CameraAccessDeniedWithoutPrompt',
        'CameraAccessRestricted',
      ]) {
        expect(AppPermissions.deniedBy(code), AppPermission.camera);
      }
    });

    test('ignores other errors', () {
      expect(AppPermissions.deniedBy('multiple_request'), isNull);
      expect(AppPermissions.deniedBy('cameraNotFound'), isNull);
    });
  });
}
