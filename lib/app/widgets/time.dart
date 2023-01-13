import 'package:flutter/material.dart';
import 'package:timeago_flutter/timeago_flutter.dart';

class TimerRefresher extends TimerRefreshWidget {
  final WidgetBuilder builder;

  const TimerRefresher({super.key, super.refreshRate, required this.builder});

  @override
  Widget build(BuildContext context) => builder(context);
}
