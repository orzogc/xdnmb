import 'package:flutter/material.dart';

import '../utils/theme.dart';

class TopCenterLoadingText extends StatelessWidget {
  const TopCenterLoadingText({super.key});

  @override
  Widget build(BuildContext context) => const Align(
        alignment: Alignment.topCenter,
        child: LoadingText(),
      );
}

// TODO: 加载语录
class LoadingText extends StatelessWidget {
  const LoadingText({super.key});

  @override
  Widget build(BuildContext context) {
    final textStyle = AppTheme.postContentTextStyle.merge(TextStyle(
      color: AppTheme.specialTextColor,
      fontWeight: FontWeight.bold,
    ));

    return Text('加载中',
        style: textStyle, strutStyle: StrutStyle.fromTextStyle(textStyle));
  }
}

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) => const Column(
        children: [
          TopCenterLoadingText(),
          Expanded(child: Center(child: CircularProgressIndicator()))
        ],
      );
}
