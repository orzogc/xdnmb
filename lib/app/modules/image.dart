import 'dart:io';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:xdnmb_api/xdnmb_api.dart' hide Image;

import '../data/services/image.dart';
import '../utils/cache.dart';
import '../utils/hidden_text.dart';
import '../utils/theme.dart';
import '../utils/toast.dart';
import '../widgets/loading.dart';
import '../widgets/post.dart';
import '../widgets/size.dart';

const Duration _overlayDuration = Duration(milliseconds: 300);

class _TopOverlay extends StatelessWidget {
  final PostBase post;

  final String? poUserHash;

  final RxBool _isShowed = false.obs;

  _TopOverlay({super.key, required this.post, this.poUserHash});

  void toggle() => _isShowed.value = !_isShowed.value;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return ChildSizeNotifier(
      builder: (context, size, child) => Obx(
        () => AnimatedPositioned(
          left: 0,
          right: 0,
          top: _isShowed.value
              ? 0
              : size.height == 0
                  ? -10000
                  : -size.height,
          curve: Curves.easeOutQuart,
          duration: _overlayDuration,
          child: child!,
        ),
      ),
      child: Container(
        color: AppTheme.overlayBackgroundColor,
        width: media.size.width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (media.padding.top > 0)
              SizedBox(
                width: media.size.width,
                height: media.padding.top,
              ),
            DefaultTextStyle.merge(
              style: TextStyle(color: AppTheme.colorDark),
              child: PostContent(
                post: post,
                showForumName: false,
                showReplyCount: false,
                contentMaxLines: 5,
                poUserHash: poUserHash,
                onHiddenText: (context, element, textStyle) => onHiddenText(
                    context: context, element: element, textStyle: textStyle),
                displayImage: false,
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _BottomOverlay extends StatelessWidget {
  final GlobalKey<_ImageState> imageKey;

  final PostBase post;

  final RxBool isLoaded;

  final RxBool _isShowed = false.obs;

  _BottomOverlay(
      {super.key,
      required this.imageKey,
      required this.post,
      required this.isLoaded});

  void toggle() => _isShowed.value = !_isShowed.value;

  Future<void> saveImage() async {
    if (isLoaded.value) {
      final image = ImageService.to;
      if (image.savePath != null) {
        final fileName = post.imageFile()!.replaceAll('/', '-');
        final path = join(image.savePath!, fileName);
        final manager = XdnmbImageCacheManager();

        try {
          final info = await manager.getFileFromCache(post.imageUrl()!);

          final imageFile = File(path);
          if (await imageFile.exists()) {
            var isSame = true;
            if (info != null) {
              if (await info.file.length() != await imageFile.length()) {
                isSame = false;
              }
            }
            if (isSame) {
              showToast('该图片已经保存在 ${image.savePath}');
              return;
            }
          }

          if (info != null) {
            await info.file.copy(path);
            showToast('图片保存在 ${image.savePath}');
          } else {
            showToast('获取缓存图片失败');
          }
        } catch (e) {
          showToast('保存图片失败：$e');
        }
      } else {
        showToast('没有存储权限无法保存图片');
      }
    } else {
      showToast('图片正在加载，无法保存');
    }
  }

  @override
  Widget build(BuildContext context) => ChildSizeNotifier(
        builder: (context, size, child) => Obx(
          () => AnimatedPositioned(
            left: 0,
            right: 0,
            bottom: _isShowed.value
                ? 0
                : size.height == 0
                    ? -10000
                    : -size.height,
            curve: Curves.easeOutQuart,
            duration: _overlayDuration,
            child: child!,
          ),
        ),
        child: Container(
          color: AppTheme.overlayBackgroundColor,
          width: MediaQuery.of(context).size.width,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              BackButton(
                  onPressed: () => Get.back(), color: AppTheme.colorDark),
              IconButton(
                  onPressed: () {
                    final size = MediaQuery.of(context).size / 2.0;
                    imageKey.currentState!
                        ._animateScaleUp(size.width, size.height);
                  },
                  icon: Icon(Icons.zoom_in, color: AppTheme.colorDark)),
              IconButton(
                  onPressed: () {
                    final size = MediaQuery.of(context).size / 2.0;
                    imageKey.currentState!
                        ._animateScaleDown(size.width, size.height);
                  },
                  icon: Icon(Icons.zoom_out, color: AppTheme.colorDark)),
              IconButton(
                  onPressed: () => imageKey.currentState!._rotate(context),
                  icon: Icon(Icons.rotate_right, color: AppTheme.colorDark)),
              IconButton(
                onPressed: saveImage,
                icon: Icon(Icons.save_alt, color: AppTheme.colorDark),
              ),
            ],
          ),
        ),
      );
}

class _Image extends StatefulWidget {
  final CachedNetworkImageProvider provider;

  const _Image({super.key, required this.provider});

  @override
  State<_Image> createState() => _ImageState();
}

class _ImageState extends State<_Image>
    with SingleTickerProviderStateMixin<_Image> {
  final TransformationController _transformationController =
      TransformationController();

  Animation<Matrix4>? _animation;

  late final AnimationController _animationController;

  void _onAnimate() {
    _transformationController.value = _animation!.value;

    if (!_animationController.isAnimating) {
      _animation!.removeListener(_onAnimate);
      _animation = null;
      _animationController.reset();
    }
  }

  void _animateReset() {
    if (!_animationController.isAnimating) {
      _animationController.reset();
      _animation = Matrix4Tween(
              begin: _transformationController.value, end: Matrix4.identity())
          .animate(_animationController);
      _animation!.addListener(_onAnimate);
      _animationController.forward();
    }
  }

  void _animateScaleUp(double x, double y) {
    if (!_animationController.isAnimating) {
      _animationController.reset();
      _animation = Matrix4Tween(
        begin: _transformationController.value,
        end: Matrix4.copy(_transformationController.value)
          ..scale(2.0, 2.0, 2.0)
          ..translate(-x / 2.0, -y / 2.0),
      ).animate(_animationController);
      _animation!.addListener(_onAnimate);
      _animationController.forward();
    }
  }

  void _animateScaleDown(double x, double y) {
    if (!_animationController.isAnimating) {
      _animationController.reset();
      _animation = Matrix4Tween(
        begin: _transformationController.value,
        end: Matrix4.copy(_transformationController.value)
          ..scale(0.5, 0.5, 0.5)
          ..translate(x, y),
      ).animate(_animationController);
      _animation!.addListener(_onAnimate);
      _animationController.forward();
    }
  }

  void _animateStop() {
    _animationController.stop();
    _animation?.removeListener(_onAnimate);
    _animation = null;
    _animationController.reset();
  }

  void _rotate(BuildContext context) {
    if (!_animationController.isAnimating) {
      final size = MediaQuery.of(context).size / 2.0;

      _transformationController.value =
          Matrix4.copy(_transformationController.value)
            ..translate(size.width, size.height)
            ..rotateZ(pi / 2.0)
            ..translate(-size.width, -size.height);
    }
  }

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
  }

  @override
  void dispose() {
    _animation?.removeListener(_onAnimate);
    _animation = null;

    _transformationController.dispose();
    _animationController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Offset? position;

    return GestureDetector(
      onDoubleTapDown: (details) => position = details.globalPosition,
      onDoubleTap: () {
        if (_transformationController.value == Matrix4.identity()) {
          if (position != null) {
            _animateScaleUp(position!.dx, position!.dy);
          }
        } else {
          _animateReset();
        }
      },
      child: SizedBox.expand(
        child: InteractiveViewer(
          transformationController: _transformationController,
          boundaryMargin: const EdgeInsets.all(double.infinity),
          maxScale: 10.0,
          onInteractionStart: (details) {
            if (_animationController.isAnimating) {
              _animateStop();
            }
          },
          child: Image(
            image: widget.provider,
          ),
        ),
      ),
    );
  }
}

class ImageController extends GetxController {
  final UniqueKey tag;

  final PostBase post;

  final String? poUserHash;

  ImageController({required this.tag, required this.post, this.poUserHash});
}

class ImageBinding implements Bindings {
  @override
  void dependencies() {
    Get.put(Get.arguments as ImageController);
  }
}

class ImageView extends GetView<ImageController> {
  final GlobalKey<_ImageState> _imageKey = GlobalKey();

  ImageView({super.key});

  @override
  Widget build(BuildContext context) {
    final isLoaded = false.obs;
    const quotation = Quotation();
    final topOverlay =
        _TopOverlay(post: controller.post, poUserHash: controller.poUserHash);
    final bottomOverlay = _BottomOverlay(
        imageKey: _imageKey, post: controller.post, isLoaded: isLoaded);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () {
              topOverlay.toggle();
              bottomOverlay.toggle();
            },
            onSecondaryTap: () => Get.back(),
            child: Center(
              child: CachedNetworkImage(
                imageUrl: controller.post.imageUrl()!,
                cacheManager: XdnmbImageCacheManager(),
                progressIndicatorBuilder: (context, url, progress) =>
                    loadingImageIndicatorBuilder(
                  context,
                  url,
                  progress,
                  quotation,
                  () => Obx(
                    () => !isLoaded.value
                        ? Hero(
                            tag: controller.tag,
                            child: CachedNetworkImage(
                              imageUrl: controller.post.thumbImageUrl()!,
                              cacheManager: XdnmbImageCacheManager(),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
                errorWidget: loadingImageErrorBuilder,
                imageBuilder: (context, imageProvider) {
                  isLoaded.value = true;

                  return Hero(
                    tag: controller.tag,
                    child: _Image(
                        key: _imageKey,
                        provider: imageProvider as CachedNetworkImageProvider),
                  );
                },
              ),
            ),
          ),
          topOverlay,
          bottomOverlay,
        ],
      ),
    );
  }
}
