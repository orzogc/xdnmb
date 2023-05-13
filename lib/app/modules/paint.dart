import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_painter/image_painter.dart';

import '../utils/image.dart';
import '../utils/toast.dart';
import '../widgets/color.dart';
import '../widgets/dialog.dart';
import '../widgets/image.dart';

class _Text implements TextDelegate {
  @override
  String get arrow => '箭头';

  @override
  String get changeBrushSize => '大小';

  @override
  String get changeColor => '颜色';

  @override
  String get changeMode => '模式';

  @override
  String get circle => '圆圈';

  @override
  String get clearAllProgress => '清除全部涂鸦';

  @override
  String get dashLine => '虚线';

  @override
  String get done => '完成';

  @override
  String get drawing => '笔刷';

  @override
  String get line => '直线';

  @override
  String get noneZoom => '缩放';

  @override
  String get rectangle => '四边形';

  @override
  String get text => '文字';

  @override
  String get undo => '撤回';

  const _Text();
}

class _SaveImage extends StatelessWidget {
  final VoidCallback saveImage;

  // ignore: unused_element
  const _SaveImage({super.key, required this.saveImage});

  @override
  Widget build(BuildContext context) => IconButton(
        onPressed: saveImage,
        icon: const Icon(Icons.save),
      );
}

class _Confirm extends StatelessWidget {
  /// 导出涂鸦，返回图片数据
  final AsyncValueGetter<Uint8List?> exportImage;

  // ignore: unused_element
  const _Confirm({super.key, required this.exportImage});

  @override
  Widget build(BuildContext context) => IconButton(
        onPressed: () async {
          final data = await exportImage();
          if (data != null) {
            Get.back<Uint8List>(result: data);
          } else {
            showToast('导出图片数据失败');
          }
        },
        icon: const Icon(Icons.check),
      );
}

typedef _BuildPainter = Widget Function(Uint8List image);

class _Canvas extends StatefulWidget {
  final BoxConstraints constraints;

  final _BuildPainter painter;

  // ignore: unused_element
  const _Canvas({super.key, required this.constraints, required this.painter});

  @override
  State<_Canvas> createState() => _CanvasState();
}

class _CanvasState extends State<_Canvas> {
  late Future<Uint8List> _paint;

  void _setPaint() => _paint = Future(() async {
        debugPrint(
            'blank image size: ${widget.constraints.maxWidth} ${widget.constraints.maxHeight - 52}');

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        canvas.drawPaint(Paint()..color = Colors.white);
        final image = await recorder.endRecording().toImage(
            widget.constraints.maxWidth.floor(),
            widget.constraints.maxHeight.floor() - 52);
        final data = await image.toByteData(format: ImageByteFormat.png);

        return data!.buffer.asUint8List();
      });

  @override
  void initState() {
    super.initState();

    _setPaint();
  }

  @override
  void didUpdateWidget(covariant _Canvas oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.constraints != oldWidget.constraints) {
      _setPaint();
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List>(
        future: _paint,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasError) {
            showToast('加载空白图片出错：${snapshot.error!}');
          }

          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData) {
            return widget.painter(snapshot.data!);
          }

          return const SizedBox.shrink();
        },
      );
}

class PaintController extends GetxController {
  final Rxn<Uint8List> image;

  final bool canReturnImageData;

  late GlobalKey<ImagePainterState> _painterKey;

  PaintController([Uint8List? image, this.canReturnImageData = true])
      : image = Rxn(image);
}

class PaintBinding implements Bindings {
  @override
  void dependencies() {
    Get.put(Get.arguments != null
        ? Get.arguments as PaintController
        : PaintController());
  }
}

class PaintView extends GetView<PaintController> {
  const PaintView({super.key});

  Future<Uint8List?> _exportImage() async =>
      await controller._painterKey.currentState?.exportImage();

  Future<void> _saveImage() async {
    final data = await _exportImage();
    if (data != null) {
      await saveImageData(data);
    } else {
      showToast('导出图片数据失败');
    }
  }

  Widget _painter(Uint8List image) => ImagePainter.memory(image,
      key: controller._painterKey, textDelegate: const _Text());

  Widget _imagePainter() => _painter(controller.image.value!);

  Widget _blankPainter() => LayoutBuilder(
      builder: (context, constraints) =>
          _Canvas(constraints: constraints, painter: _painter));

  @override
  Widget build(BuildContext context) => WillPopScope(
        onWillPop: () async {
          if (controller._painterKey.currentState?.isEdited ?? false) {
            final result = await Get.dialog(ApplyImageDialog(
              onApply: controller.canReturnImageData
                  ? () async {
                      final data = await _exportImage();
                      if (data != null) {
                        Get.back(result: data);
                      } else {
                        showToast('导出图片数据失败');
                      }
                    }
                  : null,
              onSave: !controller.canReturnImageData
                  ? () async {
                      Get.back(result: true);
                      await _saveImage();
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
        child: ColoredSafeArea(
          child: Scaffold(
            appBar: AppBar(
              title: const Text('涂鸦'),
              actions: [
                // TODO: 旋转涂鸦
                PickImage(onPickImage: (path) async {
                  try {
                    controller.image.value = await File(path).readAsBytes();
                  } catch (e) {
                    showToast('读取图片出错：$e');
                  }
                }),
                _SaveImage(saveImage: _saveImage),
                if (controller.canReturnImageData)
                  _Confirm(exportImage: _exportImage),
              ],
            ),
            body: Obx(
              () {
                // 为了可以读取图片
                controller._painterKey = GlobalKey<ImagePainterState>();

                return controller.image.value != null
                    ? _imagePainter()
                    : _blankPainter();
              },
            ),
          ),
        ),
      );
}
