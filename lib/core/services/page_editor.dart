import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Rotation and cropping for captured receipt pages, done off the UI thread.
abstract final class PageEditor {
  /// Rotates a JPEG file a quarter turn clockwise, in place.
  static Future<Size> rotate(String path) => compute(_rotate, path);

  static Size _rotate(String path) {
    final file = File(path);
    final decoded = img.decodeImage(file.readAsBytesSync());
    if (decoded == null) return Size.zero;
    final upright = img.bakeOrientation(decoded);
    final turned = img.copyRotate(upright, angle: 90);
    file.writeAsBytesSync(img.encodeJpg(turned, quality: 92));
    return Size(turned.width.toDouble(), turned.height.toDouble());
  }

  /// Crops to [rect] given as fractions of the upright image.
  static Future<Size> crop(String path, Rect rect) =>
      compute(_crop, (path, rect.left, rect.top, rect.width, rect.height));

  static Size _crop((String, double, double, double, double) a) {
    final (path, l, t, w, h) = a;
    final file = File(path);
    final decoded = img.decodeImage(file.readAsBytesSync());
    if (decoded == null) return Size.zero;
    final upright = img.bakeOrientation(decoded);
    final x = (l * upright.width).round().clamp(0, upright.width - 1);
    final y = (t * upright.height).round().clamp(0, upright.height - 1);
    final cw = (w * upright.width).round().clamp(1, upright.width - x);
    final ch = (h * upright.height).round().clamp(1, upright.height - y);
    final cropped = img.copyCrop(upright, x: x, y: y, width: cw, height: ch);
    file.writeAsBytesSync(img.encodeJpg(cropped, quality: 92));
    return Size(cropped.width.toDouble(), cropped.height.toDouble());
  }

  /// Finds the paper against a darker background: the bounding box of
  /// pixels much brighter than the image border. Returns fractions.
  static Future<Rect> autoBounds(String path) => compute(_bounds, path);

  static Rect _bounds(String path) {
    final decoded = img.decodeImage(File(path).readAsBytesSync());
    if (decoded == null) return const Rect.fromLTWH(0, 0, 1, 1);
    final small = img.copyResize(img.bakeOrientation(decoded), width: 240);
    final w = small.width, h = small.height;
    double lum(int x, int y) =>
        small.getPixel(x, y).luminanceNormalized.toDouble();

    var border = 0.0;
    var n = 0;
    for (var x = 0; x < w; x++) {
      border += lum(x, 0) + lum(x, h - 1);
      n += 2;
    }
    for (var y = 0; y < h; y++) {
      border += lum(0, y) + lum(w - 1, y);
      n += 2;
    }
    final threshold = (border / n) + 0.18;

    var minX = w, minY = h, maxX = 0, maxY = 0;
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        if (lum(x, y) > threshold) {
          if (x < minX) minX = x;
          if (x > maxX) maxX = x;
          if (y < minY) minY = y;
          if (y > maxY) maxY = y;
        }
      }
    }
    if (maxX - minX < w * 0.2 || maxY - minY < h * 0.2) {
      return const Rect.fromLTWH(0, 0, 1, 1);
    }
    return Rect.fromLTRB(
      (minX / w - 0.01).clamp(0, 1),
      (minY / h - 0.01).clamp(0, 1),
      ((maxX + 1) / w + 0.01).clamp(0, 1),
      ((maxY + 1) / h + 0.01).clamp(0, 1),
    );
  }

  static Future<Uint8List> read(String path) => File(path).readAsBytes();
}
