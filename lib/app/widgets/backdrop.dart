import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/services/settings.dart';
import '../utils/padding.dart';
import '../utils/theme.dart';
import 'listenable.dart';

class BackdropController {
  static final BackdropController controller = BackdropController();

  final RxBool _isShowBackLayer = false.obs;

  VoidCallback? _toggleFrontLayer;

  bool get isShowBackLayer => _isShowBackLayer.value;

  bool get _hasBackdrop => _toggleFrontLayer != null;

  BackdropController();

  void toggleFrontLayer() {
    if (_hasBackdrop) {
      _toggleFrontLayer!();
    }
  }

  void showBackLayer() {
    if (_hasBackdrop && !isShowBackLayer) {
      _toggleFrontLayer!();
    }
  }

  void hideBackLayer() {
    if (_hasBackdrop && isShowBackLayer) {
      _toggleFrontLayer!();
    }
  }

  /// [callback]参数为backdrop是否显示
  StreamSubscription<bool> listen(ValueChanged<bool> callback) =>
      _isShowBackLayer.listen(callback);
}

class Backdrop extends StatefulWidget {
  final double height;

  final double appBarHeight;

  final double topPadding;

  final Widget frontLayer;

  final Widget backLayer;

  const Backdrop(
      {super.key,
      required this.height,
      required this.appBarHeight,
      required this.topPadding,
      required this.frontLayer,
      required this.backLayer});

  @override
  State<Backdrop> createState() => _BackdropState();
}

class _BackdropState extends State<Backdrop>
    with SingleTickerProviderStateMixin<Backdrop> {
  static const Duration _duration = Duration(milliseconds: 300);

  late final AnimationController _animationController;

  late final Animation<Offset> _slideAnimation;

  late final Animation<double> _scaleAnimation;

  double get _frontLayerBodyHeight => widget.height - widget.appBarHeight;

  bool get _isShowBackLayer =>
      _animationController.status != AnimationStatus.dismissed;

  void _showBackLayer() =>
      _animationController.animateTo(_animationController.upperBound,
          duration: _duration *
              (_animationController.upperBound - _animationController.value),
          curve: AppTheme.slideCurve);

  void _hideBackLayer() =>
      _animationController.animateBack(_animationController.lowerBound,
          duration: _duration *
              (_animationController.value - _animationController.lowerBound),
          curve: AppTheme.slideCurve);

  void _updateController([AnimationStatus? status]) =>
      BackdropController.controller._isShowBackLayer.value = _isShowBackLayer;

  void _toggleFrontLayer() {
    if (mounted && !_animationController.isAnimating) {
      if (!_isShowBackLayer) {
        _animationController.value = widget.topPadding / widget.height;
        _showBackLayer();
      } else {
        _hideBackLayer();
      }
    }
  }

  void _truncate() {
    if (_animationController.value <
            (widget.topPadding - 0.001) / widget.height &&
        _animationController.value > _animationController.lowerBound) {
      _animationController.value = _animationController.lowerBound;
    }
  }

  void _onVerticalDragStart(DragStartDetails details) {
    if (!_isShowBackLayer) {
      _animationController.value = widget.topPadding / widget.height;
    }
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    final delta = details.primaryDelta;
    if (delta != null) {
      _animationController.value += delta / _frontLayerBodyHeight;
    }
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity;
    if (velocity != null) {
      if (velocity > 0.0) {
        _showBackLayer();
      } else if (velocity < 0.0) {
        _hideBackLayer();
      } else if (velocity == 0.0 && _animationController.value > 0.5) {
        _showBackLayer();
      } else {
        _hideBackLayer();
      }
    }
  }

  @override
  void initState() {
    super.initState();

    _animationController =
        AnimationController(vsync: this, duration: _duration);

    // 这里调用_updateController()会导致rebuild
    //_updateController();
    BackdropController.controller._toggleFrontLayer = _toggleFrontLayer;

    _animationController.addStatusListener(_updateController);
    _animationController.addListener(_truncate);

    _slideAnimation = Tween(
            begin: Offset.zero,
            end: Offset(0.0, _frontLayerBodyHeight / widget.height))
        .animate(_animationController);
    _scaleAnimation =
        Tween(begin: 0.85, end: 1.0).animate(_animationController);
  }

  @override
  void dispose() {
    BackdropController.controller._toggleFrontLayer = null;
    _animationController.removeStatusListener(_updateController);
    _animationController.removeListener(_truncate);
    _animationController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;
    final theme = Theme.of(context);
    final bottomPadding = getViewPadding(context).bottom;

    return Stack(
      children: [
        SizedBox(
          height: widget.height - widget.appBarHeight,
          child: Padding(
            padding: EdgeInsets.only(top: widget.topPadding),
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
                  child: ListenBuilder(
                    listenable: settings.backLayerDragHeightRatioListenable,
                    builder: (context, child) => SizedBox(
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
          position: _slideAnimation,
          child: Stack(
            children: [
              widget.frontLayer,
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onVerticalDragStart: _onVerticalDragStart,
                onVerticalDragUpdate: _onVerticalDragUpdate,
                onVerticalDragEnd: _onVerticalDragEnd,
                child: ListenBuilder(
                  listenable: settings.frontLayerDragHeightRatioListenable,
                  builder: (context, child) => SizedBox(
                    width: double.infinity,
                    height: widget.topPadding +
                        widget.appBarHeight +
                        (widget.height -
                                widget.topPadding -
                                widget.appBarHeight) *
                            settings.frontLayerDragHeightRatio,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (bottomPadding > 0.0)
          Positioned.fill(
            top: widget.height,
            bottom: widget.height + bottomPadding,
            child: Container(
              width: double.infinity,
              height: bottomPadding,
              color: theme.primaryColor,
            ),
          ),
      ],
    );
  }
}
