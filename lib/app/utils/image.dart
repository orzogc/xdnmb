import 'dart:collection';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:flutter/material.dart' hide Image;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart';
import 'package:get/get.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

import '../data/services/image.dart';
import '../data/services/persistent.dart';
import '../data/services/settings.dart';
import 'crypto.dart';
import 'extensions.dart';
import 'http_client.dart';
import 'theme.dart';
import 'time.dart';
import 'toast.dart';

// ignore: implementation_imports
import 'package:flutter_cache_manager/src/cache_store.dart';
// ignore: implementation_imports
import 'package:flutter_cache_manager/src/storage/cache_object.dart';

final HashMap<String, String> _imageHashMap = HashMap();

class _XdnmbCacheStore extends CacheStore {
  _XdnmbCacheStore(super.config);

  @override
  Future<void> putFile(CacheObject cacheObject) {
    assert(cacheObject.url != cacheObject.key);

    // 不保存图片URL
    final newCacheObject = cacheObject.copyWith(url: cacheObject.key);

    return super.putFile(newCacheObject);
  }
}

class XdnmbImageCacheManager extends CacheManager with ImageCacheManager {
  static const String _key = 'xdnmbImageCache';

  static final Config _config = Config(
    _key,
    maxNrOfCacheObjects: SettingsService.to.cacheImageCount,
    fileService: HttpFileService(httpClient: XdnmbHttpClient()),
  );

  static final XdnmbImageCacheManager _manager =
      XdnmbImageCacheManager._internal();

  factory XdnmbImageCacheManager() => _manager;

  XdnmbImageCacheManager._internal()
      // ignore: invalid_use_of_visible_for_testing_member
      : super.custom(_config, cacheStore: _XdnmbCacheStore(_config));
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

String hashImage(String imageName, [int? length]) {
  assert(length == null || (length > 0 && length <= 64));

  final hash = _imageHashMap[imageName];

  if (hash == null) {
    final digest =
        sha512256Hash(imageName, salt: PersistentDataService.to.imageHashSalt);
    _imageHashMap[imageName] = digest;

    return digest.substring(0, length);
  } else {
    return hash.substring(0, length);
  }
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

// 保存成功返回`true`，失败返回`false`
Future<bool> saveImageData(Uint8List imageData, [String? imageName]) async {
  final image = ImageService.to;
  final savePath = ImageService.savePath;

  try {
    final filename = imageName ?? _imageFilename(imageData);

    if (GetPlatform.isIOS) {
      if (image.hasPhotoLibraryPermission) {
        if (savePath != null) {
          final path = join(savePath, filename);
          final file = io.File(path);
          await file.writeAsBytes(imageData);

          try {
            final result =
                await ImageGallerySaver.saveFile(file.path, name: filename);
            if (result['isSuccess']) {
              showToast('图片保存到相册成功');
              return true;
            } else {
              showToast('图片保存到相册失败：${result['errorMessage']}');
              return false;
            }
          } catch (e) {
            showToast('保存图片失败：$e');
            return false;
          } finally {
            await file.delete();
          }
        } else {
          final result = await ImageGallerySaver.saveImage(imageData,
              quality: 100, name: filename);
          if (result['isSuccess']) {
            showToast('图片保存到相册成功');
            return true;
          } else {
            showToast('图片保存到相册失败：${result['errorMessage']}');
            return false;
          }
        }
      } else {
        showToast('没有图库权限无法保存图片');
        return false;
      }
    } else if (image.hasStoragePermission && savePath != null) {
      final path = join(savePath, filename);
      final file = io.File(path);
      await file.writeAsBytes(imageData);
      if (GetPlatform.isAndroid) {
        await MediaScanner.loadMedia(path: path);
      }

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

Widget loadingThumbImageIndicatorBuilder(
        BuildContext context, String url, DownloadProgress progress) =>
    progress.progress != null
        ? CircularProgressIndicator(value: progress.progress)
        : const SizedBox.shrink();

Widget loadingImageErrorBuilder(
    BuildContext context, String? url, dynamic error,
    {bool showError = true}) {
  if (showError) {
    showToast('图片加载失败: $error');
  } else {
    debugPrint(url != null ? '图片 $url 加载失败: $error' : '图片加载失败: $error');
  }

  return const Center(
    child: Text('图片加载失败', style: AppTheme.boldRed),
  );
}
