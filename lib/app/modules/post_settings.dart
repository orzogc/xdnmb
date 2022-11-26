import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

import '../data/services/settings.dart';
import '../utils/extensions.dart';
import '../utils/theme.dart';
import '../widgets/dialog.dart';
import '../widgets/post.dart';
import '../widgets/scroll.dart';

class _Confirm extends StatelessWidget {
  final PostFontSettingsController controller;

  // ignore: unused_element
  const _Confirm(this.controller, {super.key});

  @override
  Widget build(BuildContext context) => IconButton(
        onPressed: () {
          final settings = SettingsService.to;

          settings.postHeaderFontSize = controller._postHeaderFontSize.value;
          settings.postHeaderFontWeight =
              controller._postHeaderFontWeight.value;
          settings.postHeaderLineHeight =
              controller._postHeaderLineHeight.value;
          settings.postHeaderLetterSpacing =
              controller._postHeaderLetterSpacing.value;
          settings.postContentFontSize = controller._postContentFontSize.value;
          settings.postContentFontWeight =
              controller._postContentFontWeight.value;
          settings.postContentLineHeight =
              controller._postContentLineHeight.value;
          settings.postContentLetterSpacing =
              controller._postContentLetterSpacing.value;

          Get.back();
        },
        icon: const Icon(Icons.check),
      );
}

class _Restore extends StatelessWidget {
  final PostFontSettingsController controller;

  // ignore: unused_element
  const _Restore(this.controller, {super.key});

  @override
  Widget build(BuildContext context) => ListTile(
        title: OverflowBar(
          spacing: 5.0,
          alignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(
              onPressed: () {
                controller._postHeaderFontSize.value =
                    SettingsService.defaultPostHeaderFontSize;
                controller._postHeaderFontWeight.value =
                    SettingsService.defaultFontWeight;
                controller._postHeaderLineHeight.value =
                    SettingsService.defaultLineHeight;
                controller._postHeaderLetterSpacing.value =
                    SettingsService.defaultLetterSpacing;
                controller._postContentFontSize.value =
                    SettingsService.defaultPostContentFontSize;
                controller._postContentFontWeight.value =
                    SettingsService.defaultFontWeight;
                controller._postContentLineHeight.value =
                    SettingsService.defaultLineHeight;
                controller._postContentLetterSpacing.value =
                    SettingsService.defaultLetterSpacing;
              },
              child: const Text('恢复默认数值'),
            ),
            Text(
              '更改后需要重启应用',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.merge(AppTheme.boldRed),
            ),
          ],
        ),
      );
}

class _FontSize extends StatelessWidget {
  final String text;

  final RxDouble fontSize;

  // ignore: unused_element
  const _FontSize({super.key, required this.text, required this.fontSize});

  @override
  Widget build(BuildContext context) => Obx(
        () => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(text),
              trailing: Text('${fontSize.value.toInt()}'),
            ),
            Slider(
              value: fontSize.value,
              min: SettingsService.minPostFontSize,
              max: SettingsService.maxPostFontSize,
              divisions: (SettingsService.maxPostFontSize -
                      SettingsService.minPostFontSize)
                  .toInt(),
              onChanged: (value) => fontSize.value = value
                  .roundToDouble()
                  .clamp(SettingsService.minPostFontSize,
                      SettingsService.maxPostFontSize),
            ),
          ],
        ),
      );
}

class _FontWeight extends StatelessWidget {
  final String text;

  final RxInt fontWeight;

  // ignore: unused_element
  const _FontWeight({super.key, required this.text, required this.fontWeight});

  @override
  Widget build(BuildContext context) => Obx(
        () => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(text),
              trailing: Text('${fontWeight.value}'),
            ),
            Slider(
              value: fontWeight.value.toDouble(),
              min: SettingsService.minFontWeight.toDouble(),
              max: SettingsService.maxFontWeight.toDouble(),
              divisions:
                  SettingsService.maxFontWeight - SettingsService.minFontWeight,
              onChanged: (value) => fontWeight.value = value.round().clamp(
                  SettingsService.minFontWeight, SettingsService.maxFontWeight),
            ),
          ],
        ),
      );
}

class _DoubleRange extends StatelessWidget {
  final String text;

  final String dialogText;

  final RxDouble rxValue;

  final double min;

  final double max;

  const _DoubleRange(
      // ignore: unused_element
      {super.key,
      required this.text,
      required this.dialogText,
      required this.rxValue,
      required this.min,
      required this.max});

  @override
  Widget build(BuildContext context) => Obx(
        () => ListTile(
          title: Text(text),
          trailing: Text('${rxValue.value}'),
          onTap: () async {
            final ratio = await Get.dialog<double>(DoubleRangeDialog(
                text: dialogText,
                initialValue: rxValue.value,
                min: min,
                max: max));

            if (ratio != null) {
              rxValue.value = ratio;
            }
          },
        ),
      );
}

class PostFontSettingsController extends GetxController {
  late final RxDouble _postHeaderFontSize;

  late final RxInt _postHeaderFontWeight;

  late final RxDouble _postHeaderLineHeight;

  late final RxDouble _postHeaderLetterSpacing;

  late final RxDouble _postContentFontSize;

  late final RxInt _postContentFontWeight;

  late final RxDouble _postContentLineHeight;

  late final RxDouble _postContentLetterSpacing;

  final ScrollController _scrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();

    final settings = SettingsService.to;

    _postHeaderFontSize = settings.postHeaderFontSize.obs;
    _postHeaderFontWeight = settings.postHeaderFontWeight.obs;
    _postHeaderLineHeight = settings.postHeaderLineHeight.obs;
    _postHeaderLetterSpacing = settings.postHeaderLetterSpacing.obs;
    _postContentFontSize = settings.postContentFontSize.obs;
    _postContentFontWeight = settings.postContentFontWeight.obs;
    _postContentLineHeight = settings.postContentLineHeight.obs;
    _postContentLetterSpacing = settings.postContentLetterSpacing.obs;
  }

  @override
  void onClose() {
    _scrollController.dispose();

    super.onClose();
  }
}

class PostFontSettingsBinding implements Bindings {
  @override
  void dependencies() {
    Get.put(PostFontSettingsController());
  }
}

class PostFontSettingsView extends GetView<PostFontSettingsController> {
  static final Post _post = Post(
      id: 50000000,
      forumId: 4,
      replyCount: 100,
      postTime: DateTime(2099),
      userHash: 'TestA12',
      name: '测试',
      title: '示例',
      content: '''>请直接说事或提问，我们不关心您是否为【新人】<br>
>我们不建议您讨论任何有关自身的恋爱话题，没人对您及您的潜在配偶发生的烂事感兴趣<br>
>请不要使用任何对于性别的转进及引战语句，我们不关心您的性别。同样的，请就事论事，我们只在意事件本身是否弱智。<br>
>正常说话便可，在此您会丢失除了您所叙述内容外的任何属性，见字（内容）如见人，建议您在熟悉氛围前放弃任何互联网的影响''');

  const PostFontSettingsView({super.key});

  @override
  Widget build(BuildContext context) => SafeArea(
        left: false,
        top: false,
        right: false,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('串字体设置'),
            actions: [_Confirm(controller)],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) => Column(
              children: [
                Obx(
                  () => ConstrainedBox(
                    constraints:
                        BoxConstraints(maxHeight: constraints.maxHeight * 0.5),
                    child: SingleChildScrollViewWithScrollbar(
                      child: PostContent(
                        post: _post,
                        showFullTime: false,
                        contentTextStyle: TextStyle(
                          fontSize: controller._postContentFontSize.value,
                          fontWeight: FontWeightExtension.fromInt(
                            controller._postContentFontWeight.value,
                          ),
                          height: controller._postContentLineHeight.value,
                          letterSpacing:
                              controller._postContentLetterSpacing.value,
                        ),
                        headerHeight: controller._postHeaderLineHeight.value,
                        headerTextStyle: TextStyle(
                          fontSize: controller._postHeaderFontSize.value,
                          fontWeight: FontWeightExtension.fromInt(
                            controller._postHeaderFontWeight.value,
                          ),
                          height: controller._postHeaderLineHeight.value <
                                  SettingsService.defaultLineHeight
                              ? controller._postHeaderLineHeight.value
                              : SettingsService.defaultLineHeight,
                          letterSpacing:
                              controller._postHeaderLetterSpacing.value,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10.0),
                Expanded(
                  child: Scrollbar(
                    controller: controller._scrollController,
                    thumbVisibility: true,
                    child: ListView(
                      controller: controller._scrollController,
                      children: [
                        _Restore(controller),
                        _FontSize(
                          text: '串首字体大小',
                          fontSize: controller._postHeaderFontSize,
                        ),
                        _FontWeight(
                          text: '串首字体粗细',
                          fontWeight: controller._postHeaderFontWeight,
                        ),
                        _DoubleRange(
                          text: '串首高度为字体大小的倍数',
                          dialogText: '倍数',
                          rxValue: controller._postHeaderLineHeight,
                          min: SettingsService.minLineHeight,
                          max: SettingsService.maxLineHeight,
                        ),
                        _DoubleRange(
                          text: '串首文字之间的距离',
                          dialogText: '间距',
                          rxValue: controller._postHeaderLetterSpacing,
                          min: SettingsService.minLetterSpacing,
                          max: SettingsService.maxLetterSpacing,
                        ),
                        _FontSize(
                          text: '串内容字体大小',
                          fontSize: controller._postContentFontSize,
                        ),
                        _FontWeight(
                          text: '串内容字体粗细',
                          fontWeight: controller._postContentFontWeight,
                        ),
                        _DoubleRange(
                          text: '串内容行高为字体大小的倍数',
                          dialogText: '倍数',
                          rxValue: controller._postContentLineHeight,
                          min: SettingsService.minLineHeight,
                          max: SettingsService.maxLineHeight,
                        ),
                        _DoubleRange(
                          text: '串内容文字之间的距离',
                          dialogText: '间距',
                          rxValue: controller._postContentLetterSpacing,
                          min: SettingsService.minLetterSpacing,
                          max: SettingsService.maxLetterSpacing,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
