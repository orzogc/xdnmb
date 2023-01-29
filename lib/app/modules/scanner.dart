import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:xdnmb/app/utils/toast.dart';

import '../data/services/user.dart';
import '../widgets/image.dart';
import '../widgets/safe_area.dart';

class QRCodeScannerView extends StatelessWidget {
  final MobileScannerController _controller = MobileScannerController(
      facing: CameraFacing.back,
      torchEnabled: false,
      formats: [BarcodeFormat.qrCode]);

  QRCodeScannerView({super.key});

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
              onPressed: () => _controller.toggleTorch(),
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
          allowDuplicates: false,
          onDetect: (barcode, args) async {
            final value = barcode.rawValue;
            if (value != null) {
              try {
                final Map<String, dynamic> data = json.decode(value);
                final name = data['name'];
                final userHash = data['cookie'];

                if (name == null || userHash == null) {
                  showToast('无效的饼干二维码');

                  Get.back();
                  return;
                }

                if (await user.addCookie(name: name, userHash: userHash)) {
                  showToast('饼干添加成功');
                } else {
                  showToast('已存在要添加的饼干');
                }

                Get.back();
              } catch (e) {
                debugPrint('扫描饼干二维码出现错误：$e');
                showToast('无效的饼干二维码');

                Get.back();
              }
            }
          },
        ),
      ),
    );
  }
}
