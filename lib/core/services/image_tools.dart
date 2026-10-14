import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class PreparedPhoto {
  const PreparedPhoto({
    required this.jpeg,
    required this.sha256,
    required this.gpsKept,
    this.takenAt,
  });

  final Uint8List jpeg;
  final String sha256;
  final bool gpsKept;
  final DateTime? takenAt;
}

/// Item photos are compressed on the phone before upload (2,000 px long
/// edge, JPEG ~80) and lose their GPS location unless the user opts in.
/// Receipt originals are kept as captured.
abstract final class ImageTools {
  static const longEdge = 2000;
  static const quality = 80;

  static String sha256Of(Uint8List bytes) => sha256.convert(bytes).toString();

  static Future<PreparedPhoto> preparePhoto(
    Uint8List original, {
    required bool keepGps,
  }) => compute(_prepare, (original, keepGps));

  static PreparedPhoto _prepare((Uint8List, bool) args) {
    final (bytes, keepGps) = args;
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return PreparedPhoto(
        jpeg: bytes,
        sha256: sha256Of(bytes),
        gpsKept: keepGps,
      );
    }
    final takenAt = _takenAt(decoded.exif);
    var image = img.bakeOrientation(decoded);
    final longest = image.width > image.height ? image.width : image.height;
    if (longest > longEdge) {
      image = image.width >= image.height
          ? img.copyResize(image, width: longEdge)
          : img.copyResize(image, height: longEdge);
    }
    final exif = img.ExifData.from(decoded.exif);
    if (!keepGps) exif.gpsIfd.data.clear();
    // Orientation is baked into the pixels now.
    exif.imageIfd.data.remove(0x0112);
    image.exif = exif;
    final jpeg = img.encodeJpg(image, quality: quality);
    return PreparedPhoto(
      jpeg: jpeg,
      sha256: sha256Of(jpeg),
      gpsKept: keepGps,
      takenAt: takenAt,
    );
  }

  /// Removes location from a JPEG without re-compressing it, for receipt
  /// originals (which keep their captured quality).
  static Future<Uint8List> stripGps(Uint8List jpeg) => compute(_stripGps, jpeg);

  static Uint8List _stripGps(Uint8List bytes) {
    final exif = img.decodeJpgExif(bytes);
    if (exif == null || exif.gpsIfd.isEmpty) return bytes;
    exif.gpsIfd.data.clear();
    return img.injectJpgExif(bytes, exif) ?? bytes;
  }

  /// A small JPEG for a warranty card or list preview.
  static Future<Uint8List> compressForUpload(Uint8List bytes) async =>
      (await preparePhoto(bytes, keepGps: false)).jpeg;

  /// EXIF `DateTimeOriginal`, e.g. `2026:09:14 18:02:11`.
  static DateTime? _takenAt(img.ExifData exif) {
    final raw =
        exif.exifIfd[0x9003]?.toString() ?? exif.imageIfd[0x0132]?.toString();
    if (raw == null || raw.length < 19) return null;
    final normal =
        '${raw.substring(0, 10).replaceAll(':', '-')}T${raw.substring(11, 19)}';
    return DateTime.tryParse(normal);
  }
}
