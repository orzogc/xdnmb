import 'dart:typed_data';

import 'package:align_positioned/align_positioned.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:xdnmb_api/xdnmb_api.dart' hide Image;

import '../data/services/image.dart';
import '../data/services/persistent.dart';
import '../data/services/settings.dart';
import '../modules/image.dart';
import '../routes/routes.dart';
import '../utils/extensions.dart';
import '../utils/image.dart';
import '../utils/toast.dart';

class _RawThumbImage extends StatelessWidget {
  final String imageUrl;

  final String cacheKey;

  final ProgressIndicatorBuilder? progressIndicatorBuilder;

  final LoadingErrorWidgetBuilder? errorWidget;

  final Widget? overlay;

  const _RawThumbImage(
      // ignore: unused_element
      {super.key,
      required this.imageUrl,
      required this.cacheKey,
      this.progressIndicatorBuilder,
      this.errorWidget,
      this.overlay});

  @override
  Widget build(BuildContext context) {
    final image = CachedNetworkImage(
      imageUrl: imageUrl,
      cacheKey: cacheKey,
      cacheManager: XdnmbImageCacheManager(),
      fit: BoxFit.contain,
      progressIndicatorBuilder: progressIndicatorBuilder,
      errorWidget: errorWidget,
    );

    return LayoutBuilder(
      builder: (context, constraints) => ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: ThumbImage.minWidth,
          maxWidth: (constraints.maxWidth / 3.0)
              .clamp(ThumbImage.minWidth, ThumbImage.maxWidth),
          minHeight: ThumbImage.minHeight,
          maxHeight: ThumbImage.maxHeight,
        ),
        child: overlay != null
            ? AlignPositioned.relative(
                alignment: Alignment.center, container: image, child: overlay!)
            : image,
      ),
    );
  }
}

class _LargeImageDialog extends StatelessWidget {
  const _LargeImageDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.titleMedium;

    return SimpleDialog(
      children: [
        SimpleDialogOption(
          onPressed: () {},
          child: Text('查看', style: textStyle),
        ),
        SimpleDialogOption(
          onPressed: () {},
          child: Text('保存', style: textStyle),
        ),
        SimpleDialogOption(
          onPressed: () {},
          child: Text('涂鸦', style: textStyle),
        ),
      ],
    );
  }
}

class _LargeImage extends StatelessWidget {
  final PostBase post;

  _LargeImage({super.key, required this.post}) : assert(post.hasImage);

  @override
  Widget build(BuildContext context) => CachedNetworkImage(
        imageUrl: post.imageUrl!,
        cacheKey: post.imageKey!,
        cacheManager: XdnmbImageCacheManager(),
        //fit: BoxFit.scaleDown,
        progressIndicatorBuilder: (context, url, progress) => _RawThumbImage(
          imageUrl: post.thumbImageUrl!,
          cacheKey: post.thumbImageKey!,
          overlay: progress.progress != null
              ? CircularProgressIndicator(value: progress.progress)
              : const SizedBox.shrink(),
        ),
        errorWidget: (context, url, error) =>
            loadingImageErrorBuilder(context, url, error, showError: false),
        imageBuilder: (context, imageProvider) => Padding(
          padding: const EdgeInsets.only(bottom: 5.0),
          child: SizedBox(
            width: double.infinity,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Image(image: imageProvider, fit: BoxFit.scaleDown),
            ),
          ),
        ),
      );
}

class ThumbImage extends StatefulWidget {
  static const double minWidth = 70.0;

  static const double maxWidth = 250.0;

  static const double minHeight = minWidth;

  static const double maxHeight = maxWidth;

  final PostBase post;

  final String? poUserHash;

  /// 涂鸦后调用，参数是图片数据
  final ValueSetter<Uint8List>? onPaintImage;

  final bool canReturnImageData;

  ThumbImage(
      {super.key,
      required this.post,
      this.poUserHash,
      this.onPaintImage,
      this.canReturnImageData = false})
      : assert(post.hasImage);

  @override
  State<ThumbImage> createState() => _ThumbImageState();
}

class _ThumbImageState extends State<ThumbImage> {
  final UniqueKey _heroTag = UniqueKey();

  bool _hasError = false;

  bool _showLargeImage = false;

  PostBase get _post => widget.post;

  Future<void> _toImage() async {
    final result = await AppRoutes.toImage(ImageController(
        heroTag: _heroTag,
        post: _post,
        poUserHash: widget.poUserHash,
        canReturnImageData: widget.canReturnImageData));
    if (widget.onPaintImage != null && result is Uint8List) {
      widget.onPaintImage!(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () async {
        if (_showLargeImage) {
          setState(() => _showLargeImage = false);
        } else if (settings.showLargeImageInPost) {
          if (mounted) {
            setState(() => _showLargeImage = true);
          }
        } else {
          await _toImage();
        }
      },
      child: Hero(
        tag: _heroTag,
        transitionOnUserGestures: true,
        child: _showLargeImage
            ? _LargeImage(post: _post)
            : _RawThumbImage(
                imageUrl: _hasError ? _post.imageUrl! : _post.thumbImageUrl!,
                cacheKey: _hasError ? _post.imageKey! : _post.thumbImageKey!,
                progressIndicatorBuilder: loadingThumbImageIndicatorBuilder,
                errorWidget: (context, url, error) {
                  // 因为部分GIF略缩图显示会出错，所以小图加载错误就加载大图
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
    );
  }
}

Future<void> pickImage(ValueSetter<String> onPickImage) async {
  final data = PersistentDataService.to;
  final image = ImageService.to;

  if (image.hasStoragePermission && image.hasPhotoLibraryPermission) {
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'xdnmb',
        initialDirectory: GetPlatform.isDesktop ? data.pictureDirectory : null,
        type: GetPlatform.isIOS ? FileType.image : FileType.custom,
        allowedExtensions:
            GetPlatform.isIOS ? null : ['gif', 'jpeg', 'jpg', 'png'],
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
}

class PickImage extends StatelessWidget {
  /// 选取图片后调用，参数为图片路径
  final ValueSetter<String> onPickImage;

  const PickImage({super.key, required this.onPickImage});

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: '加载图片',
        onPressed: () => pickImage(onPickImage),
        icon: const Icon(Icons.image),
      );
}
