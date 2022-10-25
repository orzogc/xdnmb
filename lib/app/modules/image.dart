import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:xdnmb_api/xdnmb_api.dart' hide Image;
import 'package:image_gallery_saver/image_gallery_saver.dart';

import '../data/services/image.dart';
import '../routes/routes.dart';
import '../utils/extensions.dart';
import '../utils/image.dart';
import '../utils/theme.dart';
import '../utils/toast.dart';
import '../widgets/dialog.dart';
import '../widgets/image.dart';
import '../widgets/loading.dart';
import '../widgets/post.dart';
import '../widgets/size.dart';
import 'paint.dart';

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
                displayImage: false,
                hiddenTextColor: AppTheme.colorDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomOverlay extends StatelessWidget {
  final GlobalKey<_ImageState> imageKey;

  final PostBase? post;

  final Uint8List? imageData;

  final bool isPainted;

  final bool canReturnImageData;

  final ImageDataCallback onPaint;

  final RxBool _isShowed = false.obs;

  _BottomOverlay(
      {super.key,
      required this.imageKey,
      this.post,
      this.imageData,
      required this.isPainted,
      this.canReturnImageData = false,
      required this.onPaint})
      : assert((post != null && imageData == null) ||
            (post == null && imageData != null));

  void toggle() => _isShowed.value = !_isShowed.value;

  Future<Uint8List?> _loadImage() async {
    if (imageKey.currentState != null) {
      if (post != null) {
        final manager = XdnmbImageCacheManager();
        final info = await manager.getFileFromCache(post!.imageUrl()!);
        if (info != null) {
          return await info.file.readAsBytes();
        } else {
          showToast('读取缓存图片数据失败');
        }
      } else {
        return imageData!;
      }
    }

    return null;
  }

  Future<void> _saveImage() async {
    if (imageKey.currentState != null) {
      final image = ImageService.to;
      if (image.savePath != null) {
        try {
          if (post != null) {
            final fileName = post!.imageFile()!.replaceAll('/', '-');
            final path = join(image.savePath!, fileName);
            final manager = XdnmbImageCacheManager();

            final info = await manager.getFileFromCache(post!.imageUrl()!);

            final file = File(path);
            if (!GetPlatform.isIOS && await file.exists()) {
              bool isSame = true;
              if (info != null) {
                if (await info.file.length() != await file.length()) {
                  isSame = false;
                }
              }
              if (isSame) {
                showToast('该图片已经保存在 ${image.savePath}');
                return;
              }
            }

            if (info != null) {
              if(GetPlatform.isIOS) {
                final saveResult = await ImageGallerySaver.saveImage(
                  info.file.readAsBytesSync(), 
                  quality: 100, name: fileName);
                if (!saveResult['isSuccess']) {
                  throw Exception(saveResult['error']);
                }
                showToast('图片保存到相册成功');
              } else {
                await info.file.copy(path);
                showToast('图片保存在 ${image.savePath}');
              }
            } else {
              showToast('读取缓存图片数据失败');
            }
          } else {
            saveImageData(imageData!);
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
              Flexible(
                  child: BackButton(
                      onPressed: () => Get.maybePop(),
                      color: AppTheme.colorDark)),
              Flexible(
                  child: IconButton(
                      onPressed: () {
                        final size = MediaQuery.of(context).size / 2.0;
                        imageKey.currentState
                            ?._animateScaleUp(size.width, size.height);
                      },
                      icon: Icon(Icons.zoom_in, color: AppTheme.colorDark))),
              Flexible(
                  child: IconButton(
                      onPressed: () {
                        final size = MediaQuery.of(context).size / 2.0;
                        imageKey.currentState
                            ?._animateScaleDown(size.width, size.height);
                      },
                      icon: Icon(Icons.zoom_out, color: AppTheme.colorDark))),
              Flexible(
                  child: IconButton(
                      onPressed: () => imageKey.currentState?._rotate(context),
                      icon:
                          Icon(Icons.rotate_right, color: AppTheme.colorDark))),
              Flexible(
                  child: IconButton(
                      onPressed: () async {
                        final data = await _loadImage();
                        if (data != null) {
                          final result =
                              await AppRoutes.toPaint(PaintController(data));
                          if (result is Uint8List) {
                            onPaint(result);
                          }
                        }
                      },
                      icon: Icon(Icons.brush, color: AppTheme.colorDark))),
              Flexible(
                  child: IconButton(
                      onPressed: _saveImage,
                      icon: Icon(Icons.save_alt, color: AppTheme.colorDark))),
              if (isPainted && canReturnImageData)
                Flexible(
                  child: IconButton(
                    onPressed: () {
                      Get.back<Uint8List>(result: imageData);
                    },
                    icon: Icon(
                      Icons.check,
                      color: AppTheme.colorDark,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
}

class _Image<T extends Object> extends StatefulWidget {
  final ImageProvider<T> provider;

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

  int _rotationCount = 0;

  void _onAnimate() {
    _transformationController.value = _animation!.value;

    if (!_animationController.isAnimating) {
      _animation!.removeListener(_onAnimate);
      _animation = null;
      _animationController.reset();
    }
  }

  void _animateScaleUp(double x, double y) {
    if (!_animationController.isAnimating) {
      _animationController.reset();
      final translation = _transformationController.value.getTranslation();
      final scale = _transformationController.value.getMaxScaleOnAxis();

      _animation = Matrix4Tween(
        begin: _transformationController.value,
        end: _transformationController.value.clone()
          ..rotateZ(-pi / 2.0 * _rotationCount)
          ..translate(
              (-x + translation.x) / scale, (-y + translation.y) / scale)
          ..scale(2.0, 2.0)
          ..rotateZ(pi / 2.0 * _rotationCount),
      ).animate(_animationController);
      _animation!.addListener(_onAnimate);
      _animationController.forward();
    }
  }

  void _animateScaleDown(double x, double y) {
    if (!_animationController.isAnimating) {
      _animationController.reset();
      final translation = _transformationController.value.getTranslation();
      final scale = _transformationController.value.getMaxScaleOnAxis();

      _animation = Matrix4Tween(
        begin: _transformationController.value,
        end: _transformationController.value.clone()
          ..rotateZ(-pi / 2.0 * _rotationCount)
          ..translate((x - translation.x) / (scale * 2.0),
              (y - translation.y) / (scale * 2.0))
          ..scale(0.5, 0.5)
          ..rotateZ(pi / 2.0 * _rotationCount),
      ).animate(_animationController);
      _animation!.addListener(_onAnimate);
      _animationController.forward();
    }
  }

  void _stopAnimate() {
    _animationController.stop();
    _animation?.removeListener(_onAnimate);
    _animation = null;
    _animationController.reset();
  }

  void _rotate(BuildContext context) {
    if (!_animationController.isAnimating) {
      _animationController.reset();
      final size = MediaQuery.of(context).size / 2.0;
      final translation = _transformationController.value.getTranslation();
      final scale = _transformationController.value.getMaxScaleOnAxis();

      _transformationController.value = _transformationController.value.clone()
        ..rotateZ(-pi / 2.0 * _rotationCount)
        ..translate((size.width - translation.x) / scale,
            (size.height - translation.y) / scale)
        ..rotateZ(pi / 2.0)
        ..translate((-size.width + translation.x) / scale,
            (-size.height + translation.y) / scale)
        ..rotateZ(pi / 2.0 * _rotationCount);
      _rotationCount++;
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
    _stopAnimate();

    _transformationController.dispose();
    _animationController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Offset? position;
    bool toScaleUp = true;

    return GestureDetector(
      onDoubleTapDown: (details) => position = details.globalPosition,
      onDoubleTap: () {
        if (position != null) {
          if (toScaleUp) {
            _animateScaleUp(position!.dx, position!.dy);
            toScaleUp = false;
          } else {
            _animateScaleDown(position!.dx, position!.dy);
            toScaleUp = true;
          }
        }
      },
      child: SizedBox.expand(
        child: InteractiveViewer(
          transformationController: _transformationController,
          boundaryMargin: const EdgeInsets.all(double.infinity),
          maxScale: 10.0,
          minScale: 1.0,
          onInteractionStart: (details) {
            if (_animationController.isAnimating) {
              _stopAnimate();
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

  final Rxn<PostBase> post;

  final String? poUserHash;

  final Rxn<Uint8List> imageData;

  final bool canReturnImageData;

  bool _isPainted = false;

  ImageController(
      {required this.tag,
      PostBase? post,
      this.poUserHash,
      Uint8List? imageData,
      this.canReturnImageData = false})
      : assert((post != null && imageData == null) ||
            (post == null && imageData != null)),
        post = Rxn(post),
        imageData = Rxn(imageData);
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
    const quotation = Quotation();

    return WillPopScope(
      onWillPop: () async {
        if (controller._isPainted && controller.imageData.value != null) {
          final result = await Get.dialog(ApplyImageDialog(
            onApply: controller.canReturnImageData
                ? () => Get.back(result: controller.imageData.value)
                : null,
            onSave: !controller.canReturnImageData
                ? () async {
                    await saveImageData(controller.imageData.value!);
                    Get.back(result: true);
                  }
                : null,
            onCancel: () => Get.back(result: false),
            onNotSave: () => Get.back(result: true),
          ));

          if (result is bool) {
            return result;
          }
          if (result is Uint8List) {
            Get.back<Uint8List>(result: result);
          }

          return false;
        }

        return true;
      },
      child: Obx(
        () {
          final isLoaded = (controller.imageData.value != null).obs;

          _TopOverlay? topOverlay;
          if (controller.post.value != null) {
            topOverlay = _TopOverlay(
                post: controller.post.value!,
                poUserHash: controller.poUserHash);
          }

          final bottomOverlay = _BottomOverlay(
              imageKey: _imageKey,
              post: controller.post.value,
              imageData: controller.imageData.value,
              isPainted: controller._isPainted,
              canReturnImageData: controller.canReturnImageData,
              onPaint: (imageData) {
                controller.post.value = null;
                controller.imageData.value = imageData;
                controller._isPainted = true;
              });

          return Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              children: [
                GestureDetector(
                  onTap: () {
                    topOverlay?.toggle();
                    bottomOverlay.toggle();
                  },
                  onSecondaryTap: () => Get.maybePop(),
                  child: Center(
                    child: controller.post.value != null
                        ? CachedNetworkImage(
                            imageUrl: controller.post.value!.imageUrl()!,
                            cacheManager: XdnmbImageCacheManager(),
                            progressIndicatorBuilder:
                                (context, url, progress) =>
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
                                          imageUrl: controller.post.value!
                                              .thumbImageUrl()!,
                                          cacheManager:
                                              XdnmbImageCacheManager(),
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
                                child: _Image<CachedNetworkImageProvider>(
                                  key: _imageKey,
                                  provider: imageProvider
                                      as CachedNetworkImageProvider,
                                ),
                              );
                            },
                          )
                        : Hero(
                            tag: controller.tag,
                            child: _Image<MemoryImage>(
                              key: _imageKey,
                              provider:
                                  MemoryImage(controller.imageData.value!),
                            ),
                          ),
                  ),
                ),
                if (controller.post.value != null) topOverlay!,
                bottomOverlay,
              ],
            ),
          );
        },
      ),
    );
  }
}
