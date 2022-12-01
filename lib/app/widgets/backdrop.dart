import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../data/services/settings.dart';

class BackdropController {
  final RxBool _isShowBackLayer = false.obs;

  bool get isShowBackLayer => _isShowBackLayer.value;

  VoidCallback? _toggleFrontLayer;

  BackdropController();

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

  void _onVerticalDragStart(DragStartDetails details) {
    if (!_isShowBackLayer) {
      _animationController.value =
          MediaQuery.of(context).padding.top / widget.height;
    }
  }

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

    // 这里调用_updateController()会导致rebuild
    //_updateController();
    widget.controller._toggleFrontLayer = _toggleFrontLayer;

    _animationController.addStatusListener(_updateController);
    _animationController.addListener(_truncate);

    _scaleAnimation =
        Tween(begin: 0.85, end: 1.0).animate(_animationController);
  }

  @override
  void didUpdateWidget(covariant Backdrop oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller != oldWidget.controller) {
      //_updateController();
      oldWidget.controller._toggleFrontLayer = null;
      widget.controller._toggleFrontLayer = _toggleFrontLayer;
    }
  }

  @override
  void dispose() {
    widget.controller._toggleFrontLayer = null;
    _animationController.removeStatusListener(_updateController);
    _animationController.removeListener(_truncate);
    _animationController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;
    final paddingTop = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        Container(
          color: Theme.of(context).primaryColor,
          height: widget.height - widget.appBarHeight,
          child: Padding(
            padding: EdgeInsets.only(top: paddingTop),
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: widget.backLayer,
                ),
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onVerticalDragStart: _onVerticalDragStart,
                  onVerticalDragUpdate: _onVerticalDragUpdate,
                  onVerticalDragEnd: _onVerticalDragEnd,
                  child: ValueListenableBuilder<Box>(
                    valueListenable:
                        settings.backLayerDragHeightRatioListenable,
                    builder: (context, value, child) => SizedBox(
                      width: double.infinity,
                      height: (widget.height - widget.appBarHeight) *
                          settings.backLayerDragHeightRatio,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SlideTransition(
          position: _animationOffSet(),
          child: Stack(
            children: [
              widget.frontLayer,
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onVerticalDragStart: _onVerticalDragStart,
                onVerticalDragUpdate: _onVerticalDragUpdate,
                onVerticalDragEnd: _onVerticalDragEnd,
                child: ValueListenableBuilder<Box>(
                  valueListenable: settings.frontLayerDragHeightRatioListenable,
                  builder: (context, value, child) => SizedBox(
                    width: double.infinity,
                    height: paddingTop +
                        widget.appBarHeight +
                        (widget.height - paddingTop - widget.appBarHeight) *
                            settings.frontLayerDragHeightRatio,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}