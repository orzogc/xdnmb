import 'dart:typed_data';

import 'package:mime/mime.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

import 'extensions.dart';
import 'time.dart';

String imageFilename(Uint8List imageData) {
  final time = imageFilenameTime();
  final mimeType = lookupMimeType(time, headerBytes: imageData);
  if (mimeType == null) {
    return time;
  }
  final imageType = ImageType.fromMimeType(mimeType);

  return imageType != null ? '$time.${imageType.extension()}' : time;
}

Image? getImage(Uint8List imageData) {
  final time = imageFilenameTime();
  final mimeType = lookupMimeType(time, headerBytes: imageData);
  if (mimeType != null) {
    final imageType = ImageType.fromMimeType(mimeType);
    if (imageType != null) {
      return Image('$time.${imageType.extension()}', imageData, imageType);
    }
  }

  return null;
}
