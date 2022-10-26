import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart';
import 'package:get/get.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

import '../data/services/image.dart';
import 'extensions.dart';
import 'http_client.dart';
import 'time.dart';
import 'toast.dart';

class XdnmbImageCacheManager extends CacheManager with ImageCacheManager {
  static const String _key = 'xdnmbImageCache';

  static final XdnmbImageCacheManager _manager =
      XdnmbImageCacheManager._internal();

  factory XdnmbImageCacheManager() => _manager;

  XdnmbImageCacheManager._internal()
      : super(
          Config(
            _key,
            fileService: HttpFileService(httpClient: XdnmbHttpClient()),
          ),
        );
}

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

Future<bool> saveImageData(Uint8List imageData) async {
  final savePath = ImageService.to.savePath;

  try {
    final filename = _imageFilename(imageData);

    if (GetPlatform.isIOS) {
      if (savePath != null) {
        final path = join(savePath, filename);
        final file = File(path);
        await file.writeAsBytes(imageData);

        final Map<String, dynamic> result =
            await ImageGallerySaver.saveFile(file.path, name: filename);
        await file.delete();
        if (result['isSuccess']) {
          showToast('图片保存到相册成功');
          return true;
        } else {
          showToast('图片保存到相册失败：${result['errorMessage']}');
          return false;
        }
      } else {
        final Map<String, dynamic> result = await ImageGallerySaver.saveImage(
            imageData,
            quality: 100,
            name: filename);
        if (result['isSuccess']) {
          showToast('图片保存到相册成功');
          return true;
        } else {
          showToast('图片保存到相册失败：${result['errorMessage']}');
          return false;
        }
      }
    } else if (savePath != null) {
      final path = join(savePath, filename);
      final file = File(path);
      await file.writeAsBytes(imageData);

      showToast('图片保存在 $savePath');
      return true;
    } else {
      showToast('没有存储权限无法保存图片');
      return false;
    }
  } catch (e) {
    showToast('保存图片失败：$e');
    return false;
  }
}
