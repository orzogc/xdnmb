import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:swipeable_page_route/swipeable_page_route.dart';

import '../data/services/settings.dart';

class SwipeablePageView extends StatelessWidget {
  final PageController? controller;

  final int? itemCount;

  final IndexedWidgetBuilder itemBuilder;

  final RxBool _isScrollable = true.obs;

  SwipeablePageView(
      {super.key, this.controller, this.itemCount, required this.itemBuilder});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return SettingsService.isBackdropUI
        ? Listener(
            onPointerDown: (event) {
              final route = ModalRoute.of(context);
              if (route is SwipeablePageRoute) {
                if (controller?.page == 0.0 &&
                    event.position.dx <=
                        media.size.width *
                            SettingsService.to.swipeablePageDragWidthRatio) {
                  route.canSwipe = true;
                  _isScrollable.value = false;
                } else {
                  route.canSwipe = false;
                }
              }
            },
            onPointerUp: (event) => _isScrollable.value = true,
            child: Obx(
              () => PageView.builder(
                controller: controller,
                physics: !_isScrollable.value
                    ? const NeverScrollableScrollPhysics()
                    : null,
                itemCount: itemCount,
                itemBuilder: itemBuilder,
              ),
            ),
          )
        : PageView.builder(
            controller: controller,
            itemCount: itemCount,
            itemBuilder: itemBuilder,
          );
  }
}
