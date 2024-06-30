import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../data/services/user.dart';
import '../utils/toast.dart';
import '../utils/theme.dart';
import '../widgets/color.dart';
import '../widgets/dialog.dart';
import '../widgets/image.dart';

class _ScanImage extends StatelessWidget {
  /// 选取图片后调用，参数为图片路径
  final ValueSetter<String> onPickImage;

  // ignore: unused_element
  const _ScanImage({super.key, required this.onPickImage});

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: '扫描图片',
        onPressed: () async {
          if (GetPlatform.isIOS) {
            await Get.dialog(ConfirmCancelDialog(
              content: '扫描图片需要图片里只包含二维码且图片长宽与二维码基本相同',
              confirmText: '加载图片',
              onConfirm: () {
                Get.back();
                pickImage(onPickImage);
              },
              onCancel: Get.back,
            ));
          } else {
            await pickImage(onPickImage);
          }
        },
        icon: const Icon(Icons.image),
      );
}

class QRCodeScannerView extends StatefulWidget {
  const QRCodeScannerView({super.key});

  @override
  State<QRCodeScannerView> createState() => _QRCodeScannerViewState();
}

class _QRCodeScannerViewState extends State<QRCodeScannerView> {
  final MobileScannerController _controller = MobileScannerController(
      facing: CameraFacing.back,
      detectionSpeed: DetectionSpeed.normal,
      detectionTimeoutMs: 1000,
      torchEnabled: false,
      formats: [BarcodeFormat.qrCode]);

  bool _isBack = false;

  Future<void> onDetectBarcodes(BarcodeCapture barcodes) async {
    final user = UserService.to;

    for (final barcode in barcodes.barcodes) {
      final value = barcode.rawValue;
      if (value != null) {
        try {
          final Map<String, dynamic> data = json.decode(value);
          final name = data['name'];
          final userHash = data['cookie'];

          if (name == null || userHash == null) {
            showToast('无效的饼干二维码');

            continue;
          }

          if (await user.addCookie(name: name, userHash: userHash)) {
            showToast('饼干添加成功');
          } else {
            showToast('已存在要添加的饼干');
          }
        } catch (e) {
          debugPrint('扫描饼干二维码出现错误：$e');
          showToast('无效的饼干二维码');
        }
      }
    }

    // 防止多次调用
    if (mounted && !_isBack) {
      _isBack = true;

      Get.back();
    }
  }

  @override
  void dispose() {
    _isBack = true;
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ColoredSafeArea(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('扫描饼干二维码'),
            actions: [
              _ScanImage(onPickImage: (path) async {
                try {
                  final barcodes = await _controller.analyzeImage(path);
                  if (barcodes != null) {
                    await onDetectBarcodes(barcodes);
                  } else {
                    showToast('扫描不到二维码');
                  }
                } catch (e) {
                  showToast('扫描图片里的饼干二维码失败：$e');
                }
              }),
              IconButton(
                tooltip: '切换闪光灯',
                onPressed: () {
                  if (_controller.value.torchState != TorchState.unavailable) {
                    try {
                      _controller.toggleTorch();
                    } catch (e) {
                      showToast('切换闪光灯失败：$e');
                    }
                  }
                },
                icon: ValueListenableBuilder<MobileScannerState>(
                  valueListenable: _controller,
                  builder: (context, state, child) {
                    switch (state.torchState) {
                      case TorchState.on:
                        return const Icon(Icons.flash_on);
                      case TorchState.off:
                        return const Icon(Icons.flash_off);
                      case TorchState.auto:
                        return const Icon(Icons.flash_auto);
                      case TorchState.unavailable:
                        return const Icon(Icons.no_flash);
                    }
                  },
                ),
              ),
            ],
          ),
          body: MobileScanner(
            controller: _controller,
            errorBuilder: (context, exception, widget) => Center(
              child: Text(
                exception.errorCode == MobileScannerErrorCode.permissionDenied
                    ? '应用没有相机权限，请授予应用相机权限后重启应用以便可以使用相机扫描饼干二维码'
                    : (exception.errorDetails?.message != null
                        ? '使用相机扫描饼干二维码出现错误，可能是应用没有相机权限：${exception.errorDetails?.message}'
                        : '使用相机扫描饼干二维码出现错误，可能是应用没有相机权限'),
                style: AppTheme.boldRed,
              ),
            ),
            onDetect: onDetectBarcodes,
          ),
        ),
      );
}
