import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BackdropController {
  final RxBool _isShowBackLayer = false.obs;

  bool get isShowBackLayer => _isShowBackLayer.value;

  VoidCallback? _toggleFrontLayer;

  GestureDragUpdateCallback? _onVerticalDragUpdate;

  GestureDragEndCallback? _onVerticalDragEnd;

  void toggleFrontLayer() {
    if (_toggleFrontLayer != null) {
      _toggleFrontLayer!();
    }
  }

  void showBackLayer() {
    if (_toggleFrontLayer != null && !_isShowBackLayer.value) {
      _toggleFrontLayer!();
    }
  }

  void hideBackLayer() {
    if (_toggleFrontLayer != null && _isShowBackLayer.value) {
      _toggleFrontLayer!();
    }
  }

  void onVerticalDragUpdate(DragUpdateDetails details) {
    if (_onVerticalDragUpdate != null) {
      _onVerticalDragUpdate!(details);
    }
  }

  void onVerticalDragEnd(DragEndDetails details) {
    if (_onVerticalDragEnd != null) {
      _onVerticalDragEnd!(details);
    }
  }
}

class Backdrop extends StatefulWidget {
  final BackdropController controller;

  final double height;

  final double appBarHeight;

  final Widget frontLayer;

  final Widget backLayer;

  const Backdrop(
      {super.key,
      required this.height,
      required this.controller,
      required this.appBarHeight,
      required this.frontLayer,
      required this.backLayer});

  @override
  State<Backdrop> createState() => _BackdropState();
}

class _BackdropState extends State<Backdrop>
    with SingleTickerProviderStateMixin<Backdrop> {
  late final AnimationController _animationController;

  late final Animation<double> _scaleAnimation;

  bool get _isShowBackLayer =>
      _animationController.status != AnimationStatus.dismissed;

  void _updateController([AnimationStatus? status]) =>
      widget.controller._isShowBackLayer.value = _isShowBackLayer;

  void _toggleFrontLayer() {
    if (mounted && !_animationController.isAnimating) {
      if (!_isShowBackLayer) {
        _animationController.value =
            MediaQuery.of(context).padding.top / widget.height;
        _animationController.fling(velocity: 2.0);
      } else {
        _animationController.fling(velocity: -2.0);
      }
    }
  }

  void _truncate() {
    if (_animationController.value <
            (MediaQuery.of(context).padding.top - 0.001) / widget.height &&
        _animationController.value > 0.0) {
      _animationController.value = 0.0;
    }
  }

  Animation<Offset> _animationOffSet() => Tween(
          begin: const Offset(0.0, 0.0),
          end: Offset(
              0.0, (widget.height - widget.appBarHeight) / widget.height))
      .animate(_animationController);

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    final delta = details.primaryDelta;
    if (delta != null) {
      _animationController.value +=
          delta / (widget.height - widget.appBarHeight);
    }
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity;
    if (velocity != null) {
      if (velocity > 0.0) {
        _animationController.forward();
      } else if (velocity < 0.0) {
        _animationController.reverse();
      } else if (velocity == 0.0 && _animationController.value > 0.5) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));

    _updateController();
    widget.controller._toggleFrontLayer = _toggleFrontLayer;
    widget.controller._onVerticalDragUpdate = _onVerticalDragUpdate;
    widget.controller._onVerticalDragEnd = _onVerticalDragEnd;

    _animationController.addStatusListener(_updateController);
    _animationController.addListener(_truncate);

    _scaleAnimation =
        Tween(begin: 0.85, end: 1.0).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.removeStatusListener(_updateController);
    _animationController.removeListener(_truncate);
    _animationController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          Container(
            color: Theme.of(context).primaryColor,
            height: widget.height - widget.appBarHeight,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: widget.backLayer,
            ),
          ),
          SlideTransition(
            position: _animationOffSet(),
            child: widget.frontLayer,
          ),
        ],
      );
}
