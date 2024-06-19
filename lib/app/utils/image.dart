import 'dart:collection';
import 'dart:io' as io;
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
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

class ImageConfig {
  static const int minQuality = 1;

  static const int maxQuality = 100;

  static const int defaultRotate = 0;

  static const int rotateCycle = 360;

  final int _width;

  final int _height;

  int? _minWidth;

  int? _minHeight;

  int? _quality;

  int? _rotate;

  ImageConfig({required int width, required int height})
      : assert(width > 0 && height > 0),
        _width = width,
        _height = height;

  ImageConfig._inner(
      {required int width,
      required int height,
      required int? minWidth,
      required int? minHeight,
      required int? quality,
      required int? rotate})
      : _width = width,
        _height = height,
        _minWidth = minWidth,
        _minHeight = minHeight,
        _quality = quality,
        _rotate = rotate;

  int get width => _width;

  int get height => _height;

  int get minWidth => _minWidth ?? _width;

  int get minHeight => _minHeight ?? _height;

  int get quality => _quality ?? maxQuality;

  int get rotate => _rotate ?? defaultRotate;

  bool get needToCompress =>
      minWidth != width ||
      minHeight != height ||
      quality != maxQuality ||
      rotate % rotateCycle != 0;

  set minWidth(int width) {
    assert(width > 0);

    _minWidth = width;
  }

  set minHeight(int height) {
    assert(height > 0);

    _minHeight = height;
  }

  set quality(int quality) {
    assert(quality >= minQuality && quality <= maxQuality);

    _quality = quality;
  }

  set rotate(int rotate) {
    _rotate = rotate;
  }

  ImageConfig copy() => ImageConfig._inner(
      width: _width,
      height: _height,
      minWidth: _minWidth,
      minHeight: _minHeight,
      quality: _quality,
      rotate: _rotate);
}

Future<Image> getImage(Uint8List imageData, [ImageConfig? config]) async {
  final time = filenameFromTime();
  final mimeType = lookupMimeType(time, headerBytes: imageData);
  if (mimeType != null) {
    final imageType = ImageType.fromMimeType(mimeType);
    if (imageType != null) {
      if (imageType != ImageType.gif && config != null) {
        if (GetPlatform.isAndroid || GetPlatform.isIOS || GetPlatform.isMacOS) {
          imageData = await _nativeCompressImage(imageData, config);
        } else {
          imageData =
              await compute(_dartCompressImage, (imageData, imageType, config));
        }
      }

      return Image('$time.${imageType.extension()}', imageData, imageType);
    } else {
      throw '无效的图片格式：$mimeType';
    }
  } else {
    throw '无效的图片格式';
  }
}

Future<Uint8List> _nativeCompressImage(
    Uint8List imageData, ImageConfig config) async {
  if (config.needToCompress) {
    return await FlutterImageCompress.compressWithList(imageData,
        minWidth: config.minWidth,
        minHeight: config.minHeight,
        quality: config.quality,
        rotate: config.rotate,
        format: CompressFormat.jpeg);
  } else {
    return imageData;
  }
}

Uint8List _dartCompressImage((Uint8List, ImageType, ImageConfig) data) {
  final imageData = data.$1;
  final imageType = data.$2;
  final config = data.$3;

  if (config.needToCompress) {
    late final img.Image image;
    if (imageType == ImageType.jpeg) {
      image = img.decodeJpg(imageData)!;
    } else if (imageType == ImageType.png) {
      image = img.decodePng(imageData)!;
    } else {
      throw '无法处理的图片格式：$imageType';
    }

    final scale =
        getScale(image.width, image.height, config.minWidth, config.minHeight);
    final resizedImage = img.copyResize(image,
        width: (image.width * scale).floor(),
        height: (image.height * scale).floor());
    final rotatedImage = img.copyRotate(resizedImage, angle: config.rotate);

    return img.encodeJpg(rotatedImage, quality: config.quality);
  } else {
    return imageData;
  }
}

double getScale(
  int width,
  int height,
  int minWidth,
  int minHeight,
) {
  assert(width > 0 && height > 0 && minWidth > 0 && minHeight > 0);

  final scaleW = minWidth / width;
  final scaleH = minHeight / height;
  final scale = min(1.0, max(scaleW, scaleH));

  return scale;
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
