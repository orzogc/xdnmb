import 'package:flutter/material.dart';

import '../utils/theme.dart';

// TODO: 加载语录
class Quotation extends StatelessWidget {
  const Quotation({super.key});

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: Text(
          '加载中',
          style: TextStyle(
            color: AppTheme.specialTextColor,
            fontWeight: FontWeight.bold,
          ),
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
