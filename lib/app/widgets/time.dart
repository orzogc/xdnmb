import 'package:flutter/material.dart';
import 'package:timeago_flutter/timeago_flutter.dart';

class _TimerRefresher extends TimerRefreshWidget {
  final WidgetBuilder builder;

  // ignore: unused_element
  const _TimerRefresher({super.key, super.refreshRate, required this.builder});

  @override
  Widget build(BuildContext context) => builder(context);
}

class PostTime extends StatefulWidget {
  final bool enableSwitch;

  final bool isShowRelativeTime;

  final WidgetBuilder relativeTime;

  final Widget absoluteTime;

  const PostTime(
      {super.key,
      this.enableSwitch = true,
      required this.isShowRelativeTime,
      required this.relativeTime,
      required this.absoluteTime});

  @override
  State<PostTime> createState() => _PostTimeState();
}

class _PostTimeState extends State<PostTime> {
  late bool _isShowRelativeTime;

  @override
  void initState() {
    super.initState();

    _isShowRelativeTime = widget.isShowRelativeTime;
  }

  @override
  void didUpdateWidget(covariant PostTime oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isShowRelativeTime != oldWidget.isShowRelativeTime) {
      _isShowRelativeTime = widget.isShowRelativeTime;
    }
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
      onLongPress: widget.enableSwitch
          ? () => setState(() => _isShowRelativeTime = !_isShowRelativeTime)
          : null,
      child: _isShowRelativeTime
          ? _TimerRefresher(builder: widget.relativeTime)
          : widget.absoluteTime);
}
