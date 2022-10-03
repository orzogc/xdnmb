import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_painter/image_painter.dart';

import '../utils/image.dart';
import '../utils/toast.dart';
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

typedef _ExportImageCallback = Future<Uint8List?> Function();

class _SaveImage extends StatelessWidget {
  final _ExportImageCallback exportImage;

  const _SaveImage({super.key, required this.exportImage});

  @override
  Widget build(BuildContext context) => IconButton(
        onPressed: () async {
          final data = await exportImage();
          if (data != null) {
            await saveImageData(data);
          } else {
            showToast('导出图片数据失败');
          }
        },
        icon: const Icon(Icons.save),
      );
}

class _Confirm extends StatelessWidget {
  final _ExportImageCallback exportImage;

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

class PaintController extends GetxController {
  final Rxn<Uint8List> image;

  late GlobalKey<ImagePainterState> _painterKey;

  PaintController([Uint8List? image]) : image = Rxn(image);
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

  Widget _painter(Uint8List image) => ImagePainter.memory(image,
      key: controller._painterKey, textDelegate: const _Text());

  Widget _imagePainter() => _painter(controller.image.value!);

  Widget _blankPainter() => LayoutBuilder(
        builder: (context, constraints) => FutureBuilder<Uint8List>(
          future: Future(() async {
            debugPrint(
                'blank image size: ${constraints.maxWidth} ${constraints.maxHeight - 52}');
            final recorder = PictureRecorder();
            final canvas = Canvas(recorder);
            canvas.drawPaint(Paint()..color = Colors.white);
            final image = await recorder.endRecording().toImage(
                constraints.maxWidth.floor(),
                constraints.maxHeight.floor() - 52);
            final data = await image.toByteData(format: ImageByteFormat.png);
            return data!.buffer.asUint8List();
          }),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.hasError) {
              showToast('加载空白图片出错：${snapshot.error!}');
            }

            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.hasData) {
              return _painter(snapshot.data!);
            }

            return const SizedBox.shrink();
          },
        ),
      );

  @override
  Widget build(BuildContext context) => WillPopScope(
        onWillPop: () async {
          if (controller._painterKey.currentState?.isEdited ?? false) {
            final result = await Get.dialog<bool>(SaveImageDialog(
              onSave: () async {
                final data = await _exportImage();
                if (data != null) {
                  await saveImageData(data);
                  Get.back(result: true);
                } else {
                  showToast('导出图片数据失败');
                }
              },
              onNotSave: () => Get.back(result: true),
            ));

            return result ?? false;
          }

          return true;
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('涂鸦'),
            actions: [
              _SaveImage(exportImage: _exportImage),
              PickImage(onPickImage: (path) async {
                try {
                  controller.image.value = await File(path).readAsBytes();
                } catch (e) {
                  showToast('读取图片出错：$e');
                }
              }),
              _Confirm(exportImage: _exportImage),
            ],
          ),
          body: Obx(
            () {
              controller._painterKey = GlobalKey<ImagePainterState>();

              return controller.image.value != null
                  ? _imagePainter()
                  : _blankPainter();
            },
          ),
        ),
      );
}
