import 'package:get/get.dart';

import '../../../core/services/upload_service.dart';

class HelpTopic {
  const HelpTopic(this.title, this.summary, this.steps);

  final String title;
  final String summary;
  final List<String> steps;
}

/// 51 · Help & support
class HelpController extends GetxController {
  HelpController({required this._uploads});

  final UploadService _uploads;

  static const topics = [
    HelpTopic('Scanning problems', 'Improve a photo or enter manually', [
      'Lay the receipt flat in good, even light.',
      'Keep all four edges inside the frame.',
      'For long receipts, take several photos in order.',
      'If text still is not recognised, use Manual entry.',
    ]),
    HelpTopic('Saving and connection', 'Recover an interrupted upload', [
      'Confirmed receipts are stored on this device first.',
      'Uploads resume from Home → “waiting to upload”.',
      'Retrying continues the same save, so no duplicate is created.',
      'Keep the app installed until uploads finish.',
    ]),
    HelpTopic('Privacy and deletion', 'Understand your data controls', [
      'Only you can see your vault.',
      'Export your records from Privacy & data at any time.',
      'Deleting your account removes live records and documents.',
    ]),
  ];

  bool get isOffline => !_uploads.isOnline.value;

  bool get failNextUpload => _uploads.failNextUpload.value;

  void setOffline(bool offline) => _uploads.isOnline.value = !offline;

  void setFailNextUpload(bool fail) => _uploads.failNextUpload.value = fail;
}
