import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_painter/image_painter.dart';

import '../utils/toast.dart';

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

class PaintController extends GetxController {
  final Uint8List? image;

  PaintController({this.image});
}

class PaintBinding implements Bindings {
  @override
  void dependencies() {
    Get.put(Get.arguments != null
        ? Get.arguments as PaintController
        : PaintController());
  }
}

typedef _ExportImageCallback = Future<Uint8List?> Function();

class _Confirm extends StatelessWidget {
  final _ExportImageCallback exportImage;

  const _Confirm({super.key, required this.exportImage});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () async => Get.back<Uint8List>(result: await exportImage()),
      icon: const Icon(Icons.check),
    );
  }
}

class PaintView extends GetView<PaintController> {
  final GlobalKey<ImagePainterState> _painterKey =
      GlobalKey<ImagePainterState>();

  PaintView({super.key});

  Widget _painter(Uint8List image) =>
      ImagePainter.memory(image, key: _painterKey, textDelegate: const _Text());

  Widget _imagePainter() => _painter(controller.image!);

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('涂鸦'),
        actions: [
          _Confirm(exportImage: () => _painterKey.currentState!.exportImage()),
        ],
      ),
      body: controller.image != null ? _imagePainter() : _blankPainter(),
    );
  }
}
