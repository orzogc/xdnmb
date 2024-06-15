import 'dart:collection';
import 'dart:io' as io;
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart' hide Image;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

import '../data/services/image.dart';
import '../data/services/persistent.dart';
import '../data/services/settings.dart';
import '../data/services/xdnmb_client.dart';
import 'crypto.dart';
import 'exception.dart';
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

    // 不保存图片 URL
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

class ReferenceImageCache {
  static final HashMap<int, ReferenceImageCache?> _images =
      HashMap<int, ReferenceImageCache?>();

  static Future<ReferenceImageCache?> getImage(
      int postId, int? mainPostId) async {
    if (!_images.containsKey(postId)) {
      debugPrint('串 ${postId.toPostNumber()} 有图片，开始获取其引用');

      try {
        final reference = await XdnmbClientService.to.client
            .getReference(postId, mainPostId: mainPostId);
        if (reference.hasImage) {
          _images[postId] = ReferenceImageCache(
              image: reference.image, imageExtension: reference.imageExtension);
        } else {
          _images[postId] = null;
        }
      } catch (e) {
        final message = exceptionMessage(e);
        if (message.contains('该串不存在')) {
          _images[postId] = null;
        }

        rethrow;
      }
    }

    return _images[postId];
  }

  final String image;

  final String imageExtension;

  const ReferenceImageCache(
      {required this.image, required this.imageExtension});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReferenceImageCache &&
          image == other.image &&
          imageExtension == other.imageExtension);

  @override
  int get hashCode => Object.hash(image, imageExtension);
}

String _imageFilename(Uint8List imageData) {
  final time = filenameFromTime();
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
  final time = filenameFromTime();
  final mimeType = lookupMimeType(time, headerBytes: imageData);
  if (mimeType != null) {
    final imageType = ImageType.fromMimeType(mimeType);
    if (imageType != null) {
      return Image('$time.${imageType.extension()}', imageData, imageType);
    }
  }

  return null;
}

Future<Uint8List?> loadImage(PostBase post) async {
  final manager = XdnmbImageCacheManager();
  try {
    final info = await manager.getFileFromCache(post.imageKey!);
    if (info != null) {
      debugPrint('缓存图片路径：${info.file.path}');
      return await info.file.readAsBytes();
    } else {
      showToast('读取缓存图片数据失败');
    }
  } catch (e) {
    showToast('读取缓存图片数据失败：$e');
  }

  return null;
}

Future<void> savePostImage(PostBase post) async {
  final image = ImageService.to;
  final savePath = ImageService.savePath;
  final manager = XdnmbImageCacheManager();

  try {
    final fileName = post.imageHashFileName()!;
    final info = await manager.getFileFromCache(post.imageKey!);
    if (info != null) {
      debugPrint('缓存图片路径：${info.file.path}');
      if (GetPlatform.isIOS) {
        if (image.hasPhotoLibraryPermission) {
          final result = await SaverGallery.saveFile(
              file: info.file.path, name: fileName, androidExistNotSave: true);
          if (result.isSuccess) {
            showToast('图片保存到相册成功');
          } else {
            showToast('图片保存到相册失败：${result.errorMessage}');
          }
        } else {
          showToast('没有图库权限无法保存图片');
        }
      } else if (image.hasStoragePermission && savePath != null) {
        final path = join(savePath, fileName);
        final file = io.File(path);
        if (await file.exists() &&
            await file.length() == await info.file.length()) {
          showToast('该图片已经保存在 $savePath');
          return;
        }

        await info.file.copy(path);
        if (GetPlatform.isAndroid) {
          await MediaScanner.loadMedia(path: path);
        }

        showToast('图片保存在 $savePath');
      } else {
        showToast('没有存储权限无法保存图片');
      }
    } else {
      showToast('读取缓存图片数据失败');
    }
  } catch (e) {
    showToast('保存图片失败：$e');
  }
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
            final result = await SaverGallery.saveFile(
                file: file.path, name: filename, androidExistNotSave: true);
            if (result.isSuccess) {
              showToast('图片保存到相册成功');
              return true;
            } else {
              showToast('图片保存到相册失败：${result.errorMessage}');
              return false;
            }
          } catch (e) {
            showToast('保存图片失败：$e');
            return false;
          } finally {
            await file.delete();
          }
        } else {
          final result = await SaverGallery.saveImage(imageData,
              quality: 100, name: filename, androidExistNotSave: true);
          if (result.isSuccess) {
            showToast('图片保存到相册成功');
            return true;
          } else {
            showToast('图片保存到相册失败：${result.errorMessage}');
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

Widget loadingLargeImageIndicatorBuilder(DownloadProgress progress) =>
    progress.progress != null
        ? Center(
            child: CircularProgressIndicator(value: progress.progress),
          )
        : const SizedBox.shrink();

Widget loadingImageErrorBuilder(
    BuildContext context, String? url, dynamic error,
    {bool showError = true}) {
  if (showError) {
    showToast('图片加载失败：$error');
  } else {
    debugPrint(url != null ? '图片 $url 加载失败：$error' : '图片加载失败：$error');
  }

  return const Center(
    child: Text('图片加载失败', style: AppTheme.boldRed),
  );
}

final Matrix4 identityMatrix = Matrix4.identity();

final Matrix4 _mirrorMatrix = Matrix4.identity()..rotateY(pi);

Matrix4 mirrorTransform(bool mirror) => mirror ? _mirrorMatrix : identityMatrix;
