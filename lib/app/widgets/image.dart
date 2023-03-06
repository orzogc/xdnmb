import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:xdnmb_api/xdnmb_api.dart' hide Image;

import '../data/services/image.dart';
import '../data/services/persistent.dart';
import '../modules/image.dart';
import '../routes/routes.dart';
import '../utils/extensions.dart';
import '../utils/image.dart';
import '../utils/toast.dart';

class ThumbImage extends StatefulWidget {
  static const double minWidth = 70.0;

  static const double maxWidth = 250.0;

  static const double minHeight = minWidth;

  static const double maxHeight = maxWidth;

  final PostBase post;

  final String? poUserHash;

  /// 涂鸦后调用，参数是图片数据
  final ValueSetter<Uint8List>? onImagePainted;

  final bool canReturnImageData;

  ThumbImage(
      {super.key,
      required this.post,
      this.poUserHash,
      this.onImagePainted,
      this.canReturnImageData = false})
      : assert(post.hasImage);

  @override
  State<ThumbImage> createState() => _ThumbImageState();
}

class _ThumbImageState extends State<ThumbImage> {
  final UniqueKey _heroTag = UniqueKey();

  bool _hasError = false;

  PostBase get _post => widget.post;

  @override
  Widget build(BuildContext context) => _post.hasImage
      ? GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () async {
            final result = await AppRoutes.toImage(ImageController(
                heroTag: _heroTag,
                post: _post,
                poUserHash: widget.poUserHash,
                canReturnImageData: widget.canReturnImageData));
            if (widget.onImagePainted != null && result is Uint8List) {
              widget.onImagePainted!(result);
            }
          },
          child: LayoutBuilder(
            builder: (context, constraints) => ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: ThumbImage.minWidth,
                maxWidth: (constraints.maxWidth / 3.0)
                    .clamp(ThumbImage.minWidth, ThumbImage.maxWidth),
                minHeight: ThumbImage.minHeight,
                maxHeight: ThumbImage.maxHeight,
              ),
              child: Hero(
                tag: _heroTag,
                transitionOnUserGestures: true,
                // 因为部分GIF略缩图显示会出错，所以小图加载错误就加载大图
                child: CachedNetworkImage(
                  imageUrl: _hasError ? _post.imageUrl! : _post.thumbImageUrl!,
                  cacheKey: _hasError ? _post.imageKey! : _post.thumbImageKey!,
                  fit: BoxFit.contain,
                  cacheManager: XdnmbImageCacheManager(),
                  progressIndicatorBuilder: loadingThumbImageIndicatorBuilder,
                  errorWidget: (context, url, error) {
                    if (!_hasError) {
                      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                        if (mounted) {
                          setState(() => _hasError = true);
                        }
                      });
                    }

                    return _hasError
                        ? loadingImageErrorBuilder(context, url, error,
                            showError: false)
                        : const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ),
        )
      : const SizedBox.shrink();
}

class PickImage extends StatelessWidget {
  /// 选取图片后调用，参数为图片路径
  final ValueSetter<String> onPickImage;

  const PickImage({super.key, required this.onPickImage});

  @override
  Widget build(BuildContext context) {
    final data = PersistentDataService.to;
    final image = ImageService.to;

    return IconButton(
      tooltip: '加载图片',
      onPressed: () async {
        if (image.hasStoragePermission && image.hasPhotoLibraryPermission) {
          try {
            final result = await FilePicker.platform.pickFiles(
              dialogTitle: 'xdnmb',
              initialDirectory:
                  GetPlatform.isDesktop ? data.pictureDirectory : null,
              type: GetPlatform.isIOS ? FileType.image : FileType.custom,
              allowedExtensions:
                  GetPlatform.isIOS ? null : ['jif', 'jpeg', 'jpg', 'png'],
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
        } else {
          showToast('没有权限读取图片');
        }
      },
      icon: const Icon(Icons.image),
    );
  }
}
