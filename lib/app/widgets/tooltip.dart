import 'package:flutter/material.dart';
import 'package:get/state_manager.dart';

import '../data/services/settings.dart';
import '../utils/theme.dart';

class QuestionTooltip extends StatelessWidget {
  final String message;

  const QuestionTooltip(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return Obx(() {
      settings.hasBeenDarkMode.value;

      return Tooltip(
        triggerMode: TooltipTriggerMode.tap,
        showDuration: const Duration(seconds: 5),
        preferBelow: false,
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
              size: 12,
              color: AppTheme.highlightColor,
            ),
          ),
        ),
      );
    });
  }
}
