import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/feedback.dart';

/// Phone permissions the app asks for, each at the moment it is needed.
enum AppPermission {
  camera('camera', 'take photos of receipts and the things you own'),
  photos('photos', 'add receipt and item photos from your library'),
  notifications(
    'notifications',
    'remind you before warranties and return windows end',
  );

  const AppPermission(this.label, this.purpose);

  final String label;
  final String purpose;
}

/// Once a permission is refused the phone never asks again, so the only
/// way back is the app's page in Settings.
abstract final class AppPermissions {
  static const _android = MethodChannel('box_of_receipts/app_settings');

  /// Error codes from image_picker (`photo_…`, `camera_…`) and from the
  /// camera plugin (`CameraAccess…`).
  static const _photoCodes = {'photo_access_denied', 'photo_access_restricted'};
  static const _cameraCodes = {
    'camera_access_denied',
    'camera_access_restricted',
    'CameraAccessDenied',
    'CameraAccessDeniedWithoutPrompt',
    'CameraAccessDeniedWhenEmptyResult',
    'CameraAccessRestricted',
  };

  /// The permission a plugin error [code] reports as refused, if any.
  static AppPermission? deniedBy(String code) {
    if (_cameraCodes.contains(code)) return AppPermission.camera;
    if (_photoCodes.contains(code)) return AppPermission.photos;
    return null;
  }

  /// Opens this app's page in the phone's Settings.
  static Future<bool> openSettings() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        return await launchUrl(Uri.parse('app-settings:'));
      }
      return await _android.invokeMethod<bool>('open') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Explains why [p] is needed and offers to open Settings.
  static Future<void> explainDenied(AppPermission p) async {
    final context = Get.context;
    if (context == null) return;
    final open = await Pickers.confirm(
      context,
      title: 'Allow ${p.label}',
      message:
          'Box of Receipts uses your ${p.label} to ${p.purpose}. '
          'Access is off, so your phone will not ask again. '
          'Turn it on for Box of Receipts in Settings.',
      action: 'Open Settings',
    );
    if (open) await openSettings();
  }
}
