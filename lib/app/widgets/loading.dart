import 'package:flutter/material.dart';

import '../utils/theme.dart';

// TODO: 加载语录
class Quotation extends StatelessWidget {
  const Quotation({super.key});

  @override
  Widget build(BuildContext context) {
    final textStyle = AppTheme.postContentTextStyle.merge(TextStyle(
      color: AppTheme.specialTextColor,
      fontWeight: FontWeight.bold,
    ));

    return Align(
      alignment: Alignment.topCenter,
      child: Text(
        '加载中',
        style: textStyle,
        strutStyle: StrutStyle.fromTextStyle(textStyle),
      ),
    );
  }
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
