import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppCheckbox extends StatelessWidget {
  final bool value;

  final ValueChanged<bool?>? onChanged;

  const AppCheckbox({super.key, required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) => Padding(
        padding: GetPlatform.isLinux
            ? const EdgeInsets.only(top: 5.0)
            : EdgeInsets.zero,
        child: Checkbox(value: value, onChanged: onChanged),
      );
}
