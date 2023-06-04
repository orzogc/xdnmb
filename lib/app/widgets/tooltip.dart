import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/services/settings.dart';
import '../utils/theme.dart';

class QuestionTooltip extends StatelessWidget {
  final String message;

  final double? size;

  const QuestionTooltip({super.key, required this.message, this.size = 12});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return Obx(
      () {
        settings.isDarkModeRx.value;

        return Tooltip(
          triggerMode: TooltipTriggerMode.tap,
          showDuration: const Duration(seconds: 5),
          preferBelow: settings.autoHideAppBarRx,
          message: message,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(width: 1, color: AppTheme.highlightColor),
            ),
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: Icon(
                Icons.question_mark,
                size: size,
                color: AppTheme.highlightColor,
              ),
            ),
          ),
        );
      },
    );
  }
}
