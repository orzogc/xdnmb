import 'package:anchor_scroll_controller/anchor_scroll_controller.dart';
import 'package:flutter/material.dart';

import '../modules/post_list.dart';
import '../utils/extensions.dart';
import '../utils/notify.dart';

typedef PostListRefresherBuilder = Widget Function(
    BuildContext context, int refresh);

class PostListRefresher extends StatefulWidget {
  final PostListController controller;

  final PostListRefresherBuilder builder;

  const PostListRefresher(
      {super.key, required this.controller, required this.builder});

  @override
  State<PostListRefresher> createState() => _PostListRefresherState();
}

class _PostListRefresherState extends State<PostListRefresher> {
  int _refresh = 0;

  void _addRefresh() => _refresh++;

  @override
  void initState() {
    super.initState();

    widget.controller.addListener(_addRefresh);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_addRefresh);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) => NotifyBuilder(
      animation: widget.controller,
      builder: (context, child) => widget.builder(context, _refresh));
}

typedef PostListAnchorRefresherBuilder = Widget Function(
    BuildContext context, AnchorScrollController anchorController, int refresh);

class PostListAnchorRefresher extends StatefulWidget {
  final PostListController controller;

  final PostListAnchorRefresherBuilder builder;

  const PostListAnchorRefresher(
      {super.key, required this.controller, required this.builder});

  @override
  State<PostListAnchorRefresher> createState() =>
      _PostListAnchorRefresherState();
}

class _PostListAnchorRefresherState extends State<PostListAnchorRefresher> {
  late final AnchorScrollController _anchorController;

  int _refresh = 0;

  void _addRefresh() => _refresh++;

  @override
  void initState() {
    super.initState();

    _anchorController = AnchorScrollController(
      onIndexChanged: (index, userScroll) =>
          widget.controller.page = index.getPageFromIndex(),
    );

    widget.controller.addListener(_addRefresh);
  }

  @override
  void dispose() {
    _anchorController.dispose();
    widget.controller.removeListener(_addRefresh);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) => NotifyBuilder(
      animation: widget.controller,
      builder: (context, child) =>
          widget.builder(context, _anchorController, _refresh));
}
