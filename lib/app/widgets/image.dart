import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:xdnmb_api/xdnmb_api.dart' hide Image;

import '../data/services/persistent.dart';
import '../modules/image.dart';
import '../routes/routes.dart';
import '../utils/image.dart';
import '../utils/toast.dart';
import 'loading.dart';

typedef ImageDataCallback = void Function(Uint8List imageData);

class ThumbImage extends StatelessWidget {
  final PostBase post;

  final String? poUserHash;

  final ImageDataCallback? onImagePainted;

  final bool canReturnImageData;

  final UniqueKey _tag = UniqueKey();

  final RxBool _hasError = false.obs;

  ThumbImage(
      {super.key,
      required this.post,
      this.poUserHash,
      this.onImagePainted,
      this.canReturnImageData = false});

  @override
  Widget build(BuildContext context) => post.hasImage()
      ? GestureDetector(
          onTap: () async {
            final result = await AppRoutes.toImage(ImageController(
                tag: _tag,
                post: post,
                poUserHash: poUserHash,
                canReturnImageData: canReturnImageData));
            if (onImagePainted != null && result is Uint8List) {
              onImagePainted!(result);
            }
          },
          child: Hero(
            tag: _tag,
            // 部分GIF略缩图显示会出错
            child: Obx(
              () => CachedNetworkImage(
                imageUrl:
                    _hasError.value ? post.imageUrl()! : post.thumbImageUrl()!,
                fit: BoxFit.contain,
                cacheManager: XdnmbImageCacheManager(),
                progressIndicatorBuilder: loadingThumbImageIndicatorBuilder,
                errorWidget: (context, url, error) {
                  if (!_hasError.value) {
                    WidgetsBinding.instance.addPostFrameCallback(
                        (timeStamp) => _hasError.value = true);
                  }

                  return _hasError.value
                      ? loadingImageErrorBuilder(context, url, error)
                      : const SizedBox.shrink();
                },
              ),
            ),
          ),
        )
      : const SizedBox.shrink();
}

typedef PickImageCallback = void Function(String path);

class PickImage extends StatelessWidget {
  final PickImageCallback onPickImage;

  const PickImage({super.key, required this.onPickImage});

  @override
  Widget build(BuildContext context) {
    final data = PersistentDataService.to;

    return IconButton(
      onPressed: () async {
        try {
          final result = await FilePicker.platform.pickFiles(
            dialogTitle: 'xdnmb',
            initialDirectory:
                (GetPlatform.isDesktop) ? data.pictureDirectory : null,
            type: GetPlatform.isIOS ? FileType.image : FileType.custom,
            allowedExtensions: GetPlatform.isIOS ? null : ['jif', 'jpeg', 'jpg', 'png'],
            lockParentWindow: true,
          );

          if (result != null) {
            final path = result.files.single.path;
            if (path != null) {
              if (GetPlatform.isDesktop) {
                data.pictureDirectory = dirname(path);
              }
              onPickImage(path);
            } else {
              showToast('无法获取图片具体路径');
            }
          }
        } catch (e) {
          showToast('选取图片失败：$e');
        }
      },
      icon: const Icon(Icons.image),
    );
  }
}
