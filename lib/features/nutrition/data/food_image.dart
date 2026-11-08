import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

const _maxSide = 1024;
const _quality = 80;

/// Downscales so the longest side is at most 1024 px and re-encodes as JPEG (~100-200 KB),
/// off the UI thread. Throws [FormatException] if the bytes are not a readable image.
Future<Uint8List> prepareFoodImage(Uint8List bytes) => compute(_prepare, bytes);

Uint8List _prepare(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) throw const FormatException('Unreadable image');
  var image = img.bakeOrientation(decoded);
  final longest = max(image.width, image.height);
  if (longest > _maxSide) {
    image = img.copyResize(image,
        width: image.width >= image.height ? _maxSide : null,
        height: image.height > image.width ? _maxSide : null,
        interpolation: img.Interpolation.average);
  }
  return Uint8List.fromList(img.encodeJpg(image, quality: _quality));
}
