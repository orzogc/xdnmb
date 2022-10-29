import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../utils/theme.dart';
import '../utils/toast.dart';

typedef ThumbImageBuilder = Widget Function();

// TODO: 加载语录
class Quotation extends StatelessWidget {
  const Quotation({super.key});

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: Text(
          '加载中',
          style:
              TextStyle(color: specialTextColor(), fontWeight: FontWeight.bold),
        ),
      );
}

class QuotationLoadingIndicator extends StatelessWidget {
  const QuotationLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) => Column(
        children: const [
          Quotation(),
          Expanded(child: Center(child: CircularProgressIndicator()))
        ],
      );
}

Widget loadingThumbImageIndicatorBuilder(
        BuildContext context, String url, DownloadProgress progress) =>
    progress.progress != null
        ? CircularProgressIndicator(value: progress.progress)
        : const SizedBox.shrink();

Widget loadingImageIndicatorBuilder(BuildContext context, String url,
    DownloadProgress progress, Quotation quotation, ThumbImageBuilder builder) {
  return Stack(
    children: [
      const Align(alignment: Alignment.topCenter, child: Quotation()),
      Center(child: builder()),
      if (progress.progress != null)
        Center(
          child: CircularProgressIndicator(value: progress.progress),
        ),
    ],
  );
}

// TODO: 点击重新加载
Widget loadingImageErrorBuilder(
    BuildContext context, String? url, dynamic error,
    {bool showError = true}) {
  if (showError) {
    showToast('图片加载失败: $error');
  } else {
    debugPrint(url != null ? '图片 $url 加载失败: $error' : '图片加载失败: $error');
  }

  return const Center(
    child: Text('图片加载失败', style: AppTheme.boldRed),
  );
}
