import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:path/path.dart';
import 'package:xdnmb_api/xdnmb_api.dart' hide Image;

import '../data/services/image.dart';
import '../data/services/settings.dart';
import '../routes/routes.dart';
import '../utils/extensions.dart';
import '../utils/image.dart';
import '../utils/padding.dart';
import '../utils/theme.dart';
import '../utils/toast.dart';
import '../widgets/dialog.dart';
import '../widgets/loading.dart';
import '../widgets/post.dart';
import '../widgets/safe_area.dart';
import '../widgets/size.dart';
import 'paint.dart';

const Duration _overlayDuration = Duration(milliseconds: 300);

class _TopOverlay extends StatelessWidget {
  final PostBase post;

  final String? poUserHash;

  final RxBool _isShowed = false.obs;

  _TopOverlay(
      // ignore: unused_element
      {super.key,
      required this.post,
      this.poUserHash});

  void _toggle() => _isShowed.value = !_isShowed.value;

  @override
  Widget build(BuildContext context) => ChildSizeNotifier(
        builder: (context, size, child) => Obx(
          () => AnimatedPositioned(
            left: 0,
            right: 0,
            top: _isShowed.value
                ? 0
                : size.height == 0
                    ? -10000
                    : -size.height,
            curve: AppTheme.slideCurve,
            duration: _overlayDuration,
            child: child!,
          ),
        ),
        child: ColoredBox(
          color: AppTheme.overlayBackgroundColor,
          child: Padding(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            child: DefaultTextStyle.merge(
              style: TextStyle(color: AppTheme.colorDark),
              child: PostContent(
                post: post,
                poUserHash: poUserHash,
                contentMaxLines: 5,
                displayImage: false,
                hiddenTextColor: AppTheme.colorDark,
                showForumName: false,
                showReplyCount: false,
              ),
            ),
          ),
        ),
      );
}

class _BottomOverlay extends StatelessWidget {
  final GlobalKey<_ImageState> imageKey;

  final Uint8List? imageData;

  final bool isPainted;

  final bool canReturnImageData;

  final VoidCallback hideOverlay;

  final VoidCallback paint;

  final VoidCallback saveImage;

  final Size size;

  final RxBool _isShowed = false.obs;

  _BottomOverlay(
      // ignore: unused_element
      {super.key,
      required this.imageKey,
      this.imageData,
      required this.isPainted,
      this.canReturnImageData = false,
      required this.hideOverlay,
      required this.paint,
      required this.saveImage,
      required this.size});

  void _toggle() => _isShowed.value = !_isShowed.value;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = getViewPadding().bottom;

    return ChildSizeNotifier(
      builder: (context, size, child) => Obx(
        () => AnimatedPositioned(
          left: 0,
          right: 0,
          bottom: _isShowed.value
              ? 0
              : size.height == 0
                  ? -10000
                  : -(size.height + bottomPadding),
          curve: AppTheme.slideCurve,
          duration: _overlayDuration,
          child: child!,
        ),
      ),
      child: ColoredBox(
        color: AppTheme.overlayBackgroundColor,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Flexible(
              child: BackButton(
                onPressed: () {
                  hideOverlay();
                  Get.maybePop();
                },
                color: AppTheme.colorDark,
              ),
            ),
            Flexible(
              child: IconButton(
                onPressed: () {
                  final halfSize = size * 0.5;
                  imageKey.currentState
                      ?._animateScaleUp(halfSize.width, halfSize.height);
                },
                icon: Icon(Icons.zoom_in, color: AppTheme.colorDark),
              ),
            ),
            Flexible(
              child: IconButton(
                onPressed: () {
                  final halfSize = size * 0.5;
                  imageKey.currentState
                      ?._animateScaleDown(halfSize.width, halfSize.height);
                },
                icon: Icon(Icons.zoom_out, color: AppTheme.colorDark),
              ),
            ),
            Flexible(
              child: IconButton(
                onPressed: () => imageKey.currentState?._rotate(size),
                icon: Icon(Icons.rotate_right, color: AppTheme.colorDark),
              ),
            ),
            Flexible(
              child: IconButton(
                onPressed: paint,
                icon: Icon(Icons.brush, color: AppTheme.colorDark),
              ),
            ),
            Flexible(
              child: IconButton(
                onPressed: saveImage,
                icon: Icon(Icons.save_alt, color: AppTheme.colorDark),
              ),
            ),
            if (isPainted && canReturnImageData && imageData != null)
              Flexible(
                child: IconButton(
                  onPressed: () {
                    Get.back<Uint8List>(result: imageData);
                  },
                  icon: Icon(Icons.check, color: AppTheme.colorDark),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ImageDialog extends StatelessWidget {
  final bool fixWidth;

  final bool fixHeight;

  final VoidCallback setFixWidth;

  final VoidCallback setFixHeight;

  final VoidCallback cancelFixWidthOrHeight;

  final VoidCallback paint;

  final VoidCallback saveImage;

  const _ImageDialog(
      // ignore: unused_element
      {super.key,
      required this.fixWidth,
      required this.fixHeight,
      required this.setFixWidth,
      required this.setFixHeight,
      required this.cancelFixWidthOrHeight,
      required this.paint,
      required this.saveImage})
      : assert(!(fixWidth && fixHeight));

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.titleMedium;

    return SimpleDialog(
      children: [
        SimpleDialogOption(
          onPressed: () {
            saveImage();
            Get.back();
          },
          child: Text('??????', style: textStyle),
        ),
        SimpleDialogOption(
          onPressed: () {
            paint();
            Get.back();
          },
          child: Text('??????', style: textStyle),
        ),
        if (!fixWidth)
          SimpleDialogOption(
            onPressed: () {
              setFixWidth();
              showToast('????????????????????????');

              Get.back();
            },
            child: Text('????????????', style: textStyle),
          )
        else
          SimpleDialogOption(
            onPressed: () {
              cancelFixWidthOrHeight();
              showToast('????????????????????????');

              Get.back();
            },
            child: Text('??????????????????', style: textStyle),
          ),
        if (!fixHeight)
          SimpleDialogOption(
            onPressed: () {
              setFixHeight();
              showToast('????????????????????????');

              Get.back();
            },
            child: Text('????????????', style: textStyle),
          )
        else
          SimpleDialogOption(
            onPressed: () {
              cancelFixWidthOrHeight();
              showToast('????????????????????????');

              Get.back();
            },
            child: Text('??????????????????', style: textStyle),
          ),
      ],
    );
  }
}

typedef _SetOpacityCallback = void Function(double opacity);

class _Image<T extends Object> extends StatefulWidget {
  final UniqueKey tag;

  final ImageProvider<T> provider;

  final _SetOpacityCallback setOpacity;

  final VoidCallback hideOverlay;

  final bool canShowDialog;

  final VoidCallback? paint;

  final VoidCallback? saveImage;

  final Size size;

  const _Image(
      {super.key,
      required this.tag,
      required this.provider,
      required this.setOpacity,
      required this.hideOverlay,
      this.canShowDialog = false,
      this.paint,
      this.saveImage,
      required this.size})
      : assert(!canShowDialog || (paint != null && saveImage != null));

  @override
  State<_Image> createState() => _ImageState();
}

class _ImageState extends State<_Image>
    with SingleTickerProviderStateMixin<_Image> {
  static const double _disposeScale = 1.1;

  static const double _opacityDistance = 500.0;

  static const double _fixedMinScale = 0.9;

  static const double _fixedMaxScale = _disposeScale;

  static const double _translationLimit = 70.0;

  final TransformationController _transformationController =
      TransformationController();

  Animation<Matrix4>? _animation;

  late final AnimationController _animationController;

  late final double _disposeLimit;

  late final double _disposeDistanceFactor;

  int _rotationCount = 0;

  Offset? _doubleTapPosition;

  bool _toScaleUp = true;

  double? _scale;

  Offset? _initialPosition;

  Offset? _currentPosition;

  Offset? _positionDelta;

  ImageStream? _imageStream;

  bool _fixWidth = false;

  bool _fixHeight = false;

  bool _isLimitMovement = false;

  int? _width;

  int? _height;

  bool _isConstrained = true;

  void _onAnimate() {
    if (_animation != null) {
      _transformationController.value = _animation!.value;
    }

    if (!_animationController.isAnimating) {
      _animation?.removeListener(_onAnimate);
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
          ..rotateZ(-pi * 0.5 * _rotationCount)
          ..translate(
              (-x + translation.x) / scale, (-y + translation.y) / scale)
          ..scale(2.0, 2.0)
          ..rotateZ(pi * 0.5 * _rotationCount),
      ).animate(_animationController);
      _animation!.addListener(_onAnimate);
      _animationController.forward();

      _isLimitMovement = false;
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
          ..rotateZ(-pi * 0.5 * _rotationCount)
          ..translate((x - translation.x) / (scale * 2.0),
              (y - translation.y) / (scale * 2.0))
          ..scale(0.5, 0.5)
          ..rotateZ(pi * 0.5 * _rotationCount),
      ).animate(_animationController);
      _animation!.addListener(_onAnimate);
      _animationController.forward();

      _isLimitMovement = false;
    }
  }

  void _stopAnimate() {
    _animationController.stop();
    _animation?.removeListener(_onAnimate);
    _animation = null;
    _animationController.reset();
  }

  void _rotate(Size bodySize) {
    if (!_animationController.isAnimating) {
      _animationController.reset();
      final size = bodySize * 0.5;
      final translation = _transformationController.value.getTranslation();
      final scale = _transformationController.value.getMaxScaleOnAxis();

      _transformationController.value = _transformationController.value.clone()
        ..rotateZ(-pi * 0.5 * _rotationCount)
        ..translate((size.width - translation.x) / scale,
            (size.height - translation.y) / scale)
        ..rotateZ(pi * 0.5)
        ..translate((-size.width + translation.x) / scale,
            (-size.height + translation.y) / scale)
        ..rotateZ(pi * 0.5 * _rotationCount);
      _rotationCount++;

      _isLimitMovement = false;
    }
  }

  void _resetPosition() {
    _scale = null;
    _initialPosition = null;
    _currentPosition = null;
    _positionDelta = null;
  }

  void _setOpacity({double? opacity, Size? bodySize, Size? imageSize}) {
    if (opacity != null) {
      widget.setOpacity(opacity);
      return;
    }

    double? distance;
    if (_fixWidth && _isLimitMovement) {
      final translation = _transformationController.value.getTranslation();

      if (_isConstrained || translation.y >= 0) {
        distance = translation.y.abs();
      } else if (bodySize != null && imageSize != null) {
        final distance_ = -translation.y - (imageSize.height - bodySize.height);
        distance = distance_ > 0 ? distance_ : null;
      }
    } else if (_fixHeight && _isLimitMovement) {
      final translation = _transformationController.value.getTranslation();

      if (_isConstrained || translation.x >= 0) {
        distance = translation.x.abs();
      } else if (bodySize != null && imageSize != null) {
        final distance_ = -translation.x - (imageSize.width - bodySize.width);
        distance = distance_ > 0 ? distance_ : null;
      }
    } else if (_positionDelta != null) {
      distance = _positionDelta!.distance;
    }

    if (distance != null) {
      widget.setOpacity(1.0 - (distance / _opacityDistance).clamp(0.0, 1.0));
    } else {
      widget.setOpacity(1.0);
    }
  }

  void _clampTranslation(Size bodySize, Size? imageSize) {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    final translation = _transformationController.value.getTranslation();

    if (_width != null && _height != null) {
      final ratio =
          min(min(bodySize.width / _width!, bodySize.height / _height!), 1.0);
      final width = imageSize?.width ?? _width! * ratio;
      final height = imageSize?.height ?? _height! * ratio;

      // ??????????????????????????????????????????
      final horizontal = max((bodySize.width - width) * 0.5, 0.0);
      final vertical = max((bodySize.height - height) * 0.5, 0.0);

      // ?????????????????????????????????????????????
      switch (_rotationCount % 4) {
        case 0:
          translation.x = min(translation.x,
              bodySize.width - horizontal * scale - _translationLimit);
          translation.x = max(translation.x,
              -((width + horizontal) * scale - _translationLimit));
          translation.y = min(translation.y,
              bodySize.height - vertical * scale - _translationLimit);
          translation.y = max(translation.y,
              -((height + vertical) * scale - _translationLimit));

          break;
        case 1:
          translation.x = min(translation.x,
              bodySize.width + (height + vertical) * scale - _translationLimit);
          translation.x =
              max(translation.x, vertical * scale + _translationLimit);
          translation.y = min(translation.y,
              bodySize.height - horizontal * scale - _translationLimit);
          translation.y = max(translation.y,
              -((width + horizontal) * scale - _translationLimit));

          break;
        case 2:
          translation.x = min(
              translation.x,
              bodySize.width +
                  (width + horizontal) * scale -
                  _translationLimit);
          translation.x =
              max(translation.x, horizontal * scale + _translationLimit);
          translation.y = min(
              translation.y,
              bodySize.height +
                  (height + vertical) * scale -
                  _translationLimit);
          translation.y =
              max(translation.y, vertical * scale + _translationLimit);

          break;
        case 3:
          translation.x = min(translation.x,
              bodySize.width - vertical * scale - _translationLimit);
          translation.x = max(translation.x,
              -((height + vertical) * scale - _translationLimit));
          translation.y = min(
              translation.y,
              bodySize.height +
                  (width + horizontal) * scale -
                  _translationLimit);
          translation.y =
              max(translation.y, horizontal * scale + _translationLimit);

          break;
      }

      _transformationController.value.setTranslation(translation);
    }
  }

  void _onDoubleTapDown(TapDownDetails details, double topPadding) =>
      _doubleTapPosition = details.globalPosition - Offset(0, topPadding);

  void _onDoubleTap() {
    if (_doubleTapPosition != null && !_animationController.isAnimating) {
      widget.hideOverlay();

      if (_toScaleUp) {
        _animateScaleUp(_doubleTapPosition!.dx, _doubleTapPosition!.dy);
        _toScaleUp = false;
      } else {
        _animateScaleDown(_doubleTapPosition!.dx, _doubleTapPosition!.dy);
        _toScaleUp = true;
      }
    }
  }

  void _onInteractionStart(ScaleStartDetails details) {
    widget.hideOverlay();

    if (_animationController.isAnimating) {
      _stopAnimate();
    }

    if (details.pointerCount == 1) {
      _scale = _transformationController.value.getMaxScaleOnAxis();
      _initialPosition = details.focalPoint;
      _currentPosition = _initialPosition;

      if (_scale! > _fixedMinScale && _scale! < _fixedMaxScale) {
        if (_fixWidth && !_isLimitMovement) {
          _isLimitMovement = true;
          _transformationController.value.setTranslation(
              _transformationController.value.getTranslation()..x = 0);
        } else if (_fixHeight && !_isLimitMovement) {
          _isLimitMovement = true;
          _transformationController.value.setTranslation(
              _transformationController.value.getTranslation()..y = 0);
        }
      } else {
        _isLimitMovement = false;
      }
    } else {
      _resetPosition();
    }

    _setOpacity(opacity: 1.0);
  }

  void _onInteractionUpdate(
      ScaleUpdateDetails details, Size bodySize, Size? imageSize) {
    if (mounted &&
        details.pointerCount == 1 &&
        _scale != null &&
        _initialPosition != null &&
        _currentPosition != null) {
      final positionDelta = details.focalPoint - _currentPosition!;
      // ??????????????????????????????
      double dx =
          ((_isLimitMovement && _fixWidth) ? 0.0 : positionDelta.dx) / _scale!;
      // ??????????????????????????????
      double dy =
          ((_isLimitMovement && _fixHeight) ? 0.0 : positionDelta.dy) / _scale!;

      switch (_rotationCount % 4) {
        case 1:
          final x = dx;
          dx = dy;
          dy = -x;
          break;
        case 2:
          dx = -dx;
          dy = -dy;
          break;
        case 3:
          final x = dx;
          dx = -dy;
          dy = x;
          break;
      }

      setState(() {
        _positionDelta = details.focalPoint - _initialPosition!;
        _currentPosition = details.focalPoint;
        _transformationController.value.translate(dx, dy);
        _clampTranslation(bodySize, imageSize);
        if (_scale! < _disposeScale) {
          _setOpacity(bodySize: bodySize, imageSize: imageSize);
        }
      });
    }
  }

  void _onInteractionEnd(
      ScaleEndDetails details, Size bodySize, Size? imageSize) {
    if (_scale != null && _positionDelta != null && _scale! < _disposeScale) {
      if (_fixWidth &&
          _isLimitMovement &&
          !_isConstrained &&
          imageSize != null) {
        final translation = _transformationController.value.getTranslation();
        final disposeDistance =
            (bodySize.height - _translationLimit) * _disposeDistanceFactor;

        if (translation.y >= disposeDistance ||
            (translation.y < 0 &&
                -translation.y - (imageSize.height - bodySize.height) >=
                    disposeDistance)) {
          Get.maybePop();
        }
      } else if (_fixHeight &&
          _isLimitMovement &&
          !_isConstrained &&
          imageSize != null) {
        final translation = _transformationController.value.getTranslation();
        final disposeDistance =
            (bodySize.width - _translationLimit) * _disposeDistanceFactor;

        if (translation.x >= disposeDistance ||
            (translation.x < 0 &&
                -translation.x - (imageSize.width - bodySize.width) >=
                    disposeDistance)) {
          Get.maybePop();
        }
      } else if (_positionDelta!.dx.abs() >= _disposeLimit ||
          _positionDelta!.dy.abs() >= _disposeLimit) {
        Get.maybePop();
      } else {
        _resetPosition();
        _setOpacity(opacity: 1.0);
      }
    } else {
      _resetPosition();
      _setOpacity(opacity: 1.0);
    }
  }

  void _updateImage(ImageInfo image, bool synchronousCall) {
    if (mounted) {
      setState(() {
        _width = image.image.width;
        _height = image.image.height;

        // ???????????????????????????????????????
        if (_height! > widget.size.height &&
            _height! / _width! > widget.size.height / widget.size.width * 1.5) {
          _fixWidth = true;
        }
      });
    }

    image.dispose();
  }

  void _resetImage() {
    if (_animationController.isAnimating) {
      _stopAnimate();
    }
    _transformationController.value = Matrix4.identity();
    _rotationCount = 0;
    _toScaleUp = true;
    _resetPosition();
    _setOpacity(opacity: 1.0);
  }

  void _setFixWidth() {
    if (mounted) {
      setState(() {
        _fixWidth = true;
        _fixHeight = false;
        _isLimitMovement = true;

        _resetImage();
      });
    }
  }

  void _setFixHeight() {
    if (mounted) {
      setState(() {
        _fixWidth = false;
        _fixHeight = true;
        _isLimitMovement = true;

        _resetImage();
      });
    }
  }

  void _cancelFixWidthOrHeight() {
    if (mounted) {
      setState(() {
        _fixWidth = false;
        _fixHeight = false;
        _isLimitMovement = false;

        _resetImage();
      });
    }
  }

  @override
  void initState() {
    super.initState();

    final settings = SettingsService.to;

    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _disposeLimit = settings.imageDisposeDistance.toDouble();
    _disposeDistanceFactor = settings.fixedImageDisposeRatio;

    _imageStream = widget.provider.resolve(const ImageConfiguration());
    _imageStream?.addListener(ImageStreamListener(_updateImage));
  }

  @override
  void didUpdateWidget(covariant _Image<Object> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.provider != oldWidget.provider) {
      final oldImageStream = _imageStream;
      _imageStream = widget.provider.resolve(const ImageConfiguration());
      if (_imageStream?.key != oldImageStream?.key) {
        final listener = ImageStreamListener(_updateImage);
        oldImageStream?.removeListener(listener);
        _imageStream?.addListener(listener);
      }
    }
  }

  @override
  void dispose() {
    _stopAnimate();

    _transformationController.dispose();
    _animationController.dispose();

    _imageStream?.removeListener(ImageStreamListener(_updateImage));

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    assert(!(_fixWidth && _fixHeight));

    // ?????????????????????????????????????????????????????????????????????`null`
    Size? imageSize;
    if (_width != null && _height != null) {
      if (_fixWidth) {
        imageSize =
            Size(widget.size.width, _height! * (widget.size.width / _width!));
        if (imageSize.height > widget.size.height) {
          // ???????????????????????????????????????
          _isConstrained = false;
        }
      } else if (_fixHeight) {
        imageSize =
            Size(_width! * (widget.size.height / _height!), widget.size.height);
        if (imageSize.width > widget.size.width) {
          // ???????????????????????????????????????
          _isConstrained = false;
        }
      } else {
        _isConstrained = true;
      }
    } else {
      _isConstrained = true;
    }

    return SizedBox.expand(
      child: GestureDetector(
        onDoubleTapDown: (details) =>
            _onDoubleTapDown(details, MediaQuery.of(context).padding.top),
        onDoubleTap: _onDoubleTap,
        onLongPress: widget.canShowDialog
            ? () {
                widget.hideOverlay();
                Get.dialog(
                  _ImageDialog(
                    fixWidth: _fixWidth,
                    fixHeight: _fixHeight,
                    setFixWidth: _setFixWidth,
                    setFixHeight: _setFixHeight,
                    cancelFixWidthOrHeight: _cancelFixWidthOrHeight,
                    paint: widget.paint!,
                    saveImage: widget.saveImage!,
                  ),
                );
              }
            : null,
        child: InteractiveViewer(
          transformationController: _transformationController,
          boundaryMargin: const EdgeInsets.all(double.infinity),
          constrained: _isConstrained,
          panEnabled: false,
          maxScale: 25.0,
          minScale: 1.0,
          onInteractionStart: _onInteractionStart,
          onInteractionUpdate: (details) =>
              _onInteractionUpdate(details, widget.size, imageSize),
          onInteractionEnd: (details) =>
              _onInteractionEnd(details, widget.size, imageSize),
          child: Hero(
            tag: widget.tag,
            child: Image(
              image: widget.provider,
              fit: (imageSize != null) ? BoxFit.contain : BoxFit.scaleDown,
              width: imageSize?.width,
              height: imageSize?.height,
            ),
          ),
        ),
      ),
    );
  }
}

class ImageController {
  final UniqueKey tag;

  final Rxn<PostBase> post;

  final String? poUserHash;

  final Rxn<Uint8List> imageData;

  final bool canReturnImageData;

  bool _isPainted = false;

  _TopOverlay? _topOverlay;

  _BottomOverlay? _bottomOverlay;

  bool _isShowOverlay = false;

  ImageController(
      {required this.tag,
      PostBase? post,
      this.poUserHash,
      Uint8List? imageData,
      this.canReturnImageData = false})
      : assert(post == null || post.hasImage()),
        assert((post != null && imageData == null) ||
            (post == null && imageData != null)),
        post = Rxn(post),
        imageData = Rxn(imageData);
}

class ImageView extends StatelessWidget {
  final ImageController _controller = Get.arguments;

  final GlobalKey<_ImageState> _imageKey = GlobalKey();

  final RxDouble _opacity = 1.0.obs;

  ImageView({super.key});

  Future<Uint8List?> _loadImage() async {
    if (_imageKey.currentState != null) {
      final post = _controller.post.value;

      if (post != null) {
        final manager = XdnmbImageCacheManager();
        try {
          final info = await manager.getFileFromCache(post.imageKey()!);
          if (info != null) {
            debugPrint('?????????????????????${info.file.path}');
            return await info.file.readAsBytes();
          } else {
            showToast('??????????????????????????????');
          }
        } catch (e) {
          showToast('?????????????????????????????????$e');
        }
      } else {
        return _controller.imageData.value!;
      }
    }

    return null;
  }

  Future<void> _paint() async {
    final data = await _loadImage();
    if (data != null) {
      final result = await AppRoutes.toPaint(PaintController(data));
      if (result is Uint8List) {
        _controller.post.value = null;
        _controller.imageData.value = result;
        _controller._isPainted = true;
      }
    }
  }

  Future<void> _saveImage() async {
    if (_imageKey.currentState != null) {
      final post = _controller.post.value;

      try {
        if (post != null) {
          final image = ImageService.to;
          final savePath = ImageService.savePath;
          final fileName = post.imageHashFileName()!;
          final manager = XdnmbImageCacheManager();

          final info = await manager.getFileFromCache(post.imageKey()!);
          if (info != null) {
            debugPrint('?????????????????????${info.file.path}');
            if (GetPlatform.isIOS) {
              if (image.hasPhotoLibraryPermission) {
                final result = await ImageGallerySaver.saveFile(info.file.path,
                    name: fileName);
                if (result['isSuccess']) {
                  showToast('???????????????????????????');
                } else {
                  showToast('??????????????????????????????${result['errorMessage']}');
                }
              } else {
                showToast('????????????????????????????????????');
              }
            } else if (image.hasStoragePermission && savePath != null) {
              final path = join(savePath, fileName);
              final file = File(path);
              if (await file.exists() &&
                  await file.length() == await info.file.length()) {
                showToast('???????????????????????? $savePath');
                return;
              }

              await info.file.copy(path);
              if (GetPlatform.isAndroid) {
                await MediaScanner.loadMedia(path: path);
              }

              showToast('??????????????? $savePath');
            } else {
              showToast('????????????????????????????????????');
            }
          } else {
            showToast('??????????????????????????????');
          }
        } else {
          saveImageData(_controller.imageData.value!);
        }
      } catch (e) {
        showToast('?????????????????????$e');
      }
    } else {
      showToast('???????????????????????????????????????????????????');
    }
  }

  void _toggleOverlay() {
    _controller._topOverlay?._toggle();
    _controller._bottomOverlay?._toggle();
    _controller._isShowOverlay = !_controller._isShowOverlay;
  }

  void _hideOverlay() {
    if (_controller._isShowOverlay) {
      _controller._topOverlay?._toggle();
      _controller._bottomOverlay?._toggle();
      _controller._isShowOverlay = false;
    }
  }

  void _setOpacity(double value) => _opacity.value = value.clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isLoaded = (_controller.imageData.value != null).obs;

    return WillPopScope(
      onWillPop: () async {
        if (_controller._isPainted && _controller.imageData.value != null) {
          final result = await Get.dialog(ApplyImageDialog(
            onApply: _controller.canReturnImageData
                ? () => Get.back(result: _controller.imageData.value)
                : null,
            onSave: !_controller.canReturnImageData
                ? () async {
                    await saveImageData(_controller.imageData.value!);
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
        () => ColoredSafeArea(
          color: Colors.black.withOpacity(_opacity.value),
          child: LayoutBuilder(builder: (context, constraints) {
            final size = Size(constraints.maxWidth,
                constraints.maxHeight - media.padding.top);

            return Obx(() {
              _controller._isShowOverlay = false;

              if (_controller.post.value != null) {
                _controller._topOverlay = _TopOverlay(
                    post: _controller.post.value!,
                    poUserHash: _controller.poUserHash);
              } else {
                _controller._topOverlay = null;
              }

              _controller._bottomOverlay = _BottomOverlay(
                  imageKey: _imageKey,
                  imageData: _controller.imageData.value,
                  isPainted: _controller._isPainted,
                  canReturnImageData: _controller.canReturnImageData,
                  hideOverlay: _hideOverlay,
                  paint: _paint,
                  saveImage: _saveImage,
                  size: size);

              final CachedNetworkImage? thumbImage = _controller.post.value !=
                      null
                  ? CachedNetworkImage(
                      imageUrl: _controller.post.value!.thumbImageUrl()!,
                      cacheKey: _controller.post.value!.thumbImageKey()!,
                      cacheManager: XdnmbImageCacheManager(),
                      errorWidget: (context, url, error) =>
                          loadingImageErrorBuilder(context, url, error,
                              showError: false),
                      imageBuilder: (context, imageProvider) =>
                          _Image<CachedNetworkImageProvider>(
                        tag: _controller.tag,
                        provider: imageProvider as CachedNetworkImageProvider,
                        setOpacity: _setOpacity,
                        hideOverlay: _hideOverlay,
                        size: size,
                      ),
                    )
                  : null;

              return Scaffold(
                backgroundColor: Colors.transparent,
                body: Stack(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: media.padding.top),
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: _toggleOverlay,
                        onSecondaryTap: () {
                          _hideOverlay();
                          Get.maybePop();
                        },
                        child: (_controller.post.value != null &&
                                thumbImage != null)
                            ? CachedNetworkImage(
                                imageUrl: _controller.post.value!.imageUrl()!,
                                cacheKey: _controller.post.value!.imageKey()!,
                                cacheManager: XdnmbImageCacheManager(),
                                progressIndicatorBuilder:
                                    (context, url, progress) => Stack(
                                  children: [
                                    Obx(
                                      () => !isLoaded.value
                                          ? thumbImage
                                          : const SizedBox.shrink(),
                                    ),
                                    const Align(
                                      alignment: Alignment.topCenter,
                                      child: Quotation(),
                                    ),
                                    if (progress.progress != null)
                                      Center(
                                        child: CircularProgressIndicator(
                                          value: progress.progress,
                                        ),
                                      ),
                                  ],
                                ),
                                errorWidget: (context, url, error) => Stack(
                                  children: [
                                    thumbImage,
                                    Align(
                                      alignment: Alignment.topCenter,
                                      child: Text(
                                        '??????????????????: $error',
                                        style: AppTheme
                                            .boldRedPostContentTextStyle,
                                        strutStyle: AppTheme
                                            .boldRedPostContentStrutStyle,
                                      ),
                                    ),
                                  ],
                                ),
                                imageBuilder: (context, imageProvider) {
                                  isLoaded.value = true;

                                  return _Image<CachedNetworkImageProvider>(
                                    key: _imageKey,
                                    tag: _controller.tag,
                                    provider: imageProvider
                                        as CachedNetworkImageProvider,
                                    setOpacity: _setOpacity,
                                    hideOverlay: _hideOverlay,
                                    canShowDialog: true,
                                    paint: _paint,
                                    saveImage: _saveImage,
                                    size: size,
                                  );
                                },
                              )
                            : (_controller.imageData.value != null
                                ? _Image<MemoryImage>(
                                    key: _imageKey,
                                    tag: _controller.tag,
                                    provider: MemoryImage(
                                        _controller.imageData.value!),
                                    setOpacity: _setOpacity,
                                    hideOverlay: _hideOverlay,
                                    canShowDialog: true,
                                    paint: _paint,
                                    saveImage: _saveImage,
                                    size: size,
                                  )
                                : const SizedBox.shrink()),
                      ),
                    ),
                    if (_controller.post.value != null &&
                        _controller._topOverlay != null)
                      _controller._topOverlay!,
                    if (_controller._bottomOverlay != null)
                      _controller._bottomOverlay!,
                  ],
                ),
              );
            });
          }),
        ),
      ),
    );
  }
}
