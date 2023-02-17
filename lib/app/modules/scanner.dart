import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:xdnmb/app/utils/toast.dart';

import '../data/services/user.dart';
import '../utils/theme.dart';
import '../widgets/image.dart';
import '../widgets/safe_area.dart';

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

  @override
  void dispose() {
    _isBack = true;
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = UserService.to;

    return ColoredSafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('扫描饼干二维码'),
          actions: [
            PickImage(onPickImage: (path) async {
              try {
                if (!await _controller.analyzeImage(path)) {
                  showToast('无效的饼干二维码');
                }
              } catch (e) {
                showToast('扫描图片里的饼干二维码失败：$e');
              }
            }),
            IconButton(
              tooltip: '切换闪光灯',
              onPressed: () {
                try {
                  _controller.toggleTorch();
                } catch (e) {
                  showToast('切换闪光灯失败：$e');
                }
              },
              icon: ValueListenableBuilder(
                valueListenable: _controller.torchState,
                builder: (context, state, child) {
                  switch (state) {
                    case TorchState.on:
                      return const Icon(Icons.flash_on);
                    case TorchState.off:
                      return const Icon(Icons.flash_off);
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
          onDetect: (barcodes) async {
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
          },
        ),
      ),
    );
  }
}
