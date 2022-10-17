import 'dart:io';
import 'dart:typed_data';

import 'package:mime/mime.dart';
import 'package:path/path.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

import '../data/services/image.dart';
import 'extensions.dart';
import 'time.dart';
import 'toast.dart';

String _imageFilename(Uint8List imageData) {
  final time = imageFilenameTime();
  final mimeType = lookupMimeType(time, headerBytes: imageData);
  if (mimeType == null) {
    return time;
  }
  final imageType = ImageType.fromMimeType(mimeType);

  return imageType != null
      ? '$time.${imageType.extension()}'
      : '$time.${extensionFromMime(mimeType)}';
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

Future<bool> saveImageData(Uint8List imageData,
    [bool isShowSuccessMessage = true]) async {
  final image = ImageService.to;

  if (image.savePath != null) {
    try {
      final filename = _imageFilename(imageData);
      final path = join(image.savePath!, filename);
      final file = File(path);
      await file.writeAsBytes(imageData);

      if (isShowSuccessMessage) {
        showToast('图片保存在 ${image.savePath}');
      }

      return true;
    } catch (e) {
      showToast('保存图片失败：$e');
      return false;
    }
  } else {
    showToast('没有存储权限无法保存图片');
    return false;
  }
}
