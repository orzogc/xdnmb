import 'dart:collection';

import 'package:float_column/float_column.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:html_to_text/html_to_text.dart';
import 'package:xdnmb_api/xdnmb_api.dart' hide Image;

import '../data/services/settings.dart';
import '../utils/regex.dart';
import '../utils/text.dart';
import '../widgets/image.dart';

Map<String, OnTagCallback> onHiddenTag(OnTagCallback onHiddenText) =>
    HashMap.fromEntries([MapEntry('h', onHiddenText)]);

class TextContent extends StatefulWidget {
  final String text;

  final int? maxLines;

  final OnLinkTapCallback? onLinkTap;

  final OnImageCallback? onImage;

  const TextContent(
      {super.key,
      required this.text,
      this.maxLines,
      this.onLinkTap,
      this.onImage});

  @override
  State<TextContent> createState() => _TextContentState();
}

class _TextContentState extends State<TextContent> {
  late final HtmlText _htmlText;

  @override
  void initState() {
    super.initState();

    _htmlText = HtmlText(
      context,
      widget.text,
      onLinkTap: widget.onLinkTap,
      onText: (context, text) => Regex.onText(text),
      onTextRecursiveParse: true,
      onImage: widget.onImage,
    );
  }

  @override
  void dispose() {
    _htmlText.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RichText(
        text: _htmlText.toTextSpan(),
        maxLines: widget.maxLines,
        overflow:
            widget.maxLines != null ? TextOverflow.ellipsis : TextOverflow.clip,
      );
}

class Content extends StatefulWidget {
  final PostBase post;

  final String? poUserHash;

  final int? maxLines;

  final OnLinkTapCallback? onLinkTap;

  final ImageDataCallback? onImagePainted;

  final bool displayImage;

  final bool canReturnImageData;

  final bool canTapHiddenText;

  final Color? hiddenTextColor;

  final TextStyle? textStyle;

  const Content(
      {super.key,
      required this.post,
      this.poUserHash,
      this.maxLines,
      this.onLinkTap,
      this.onImagePainted,
      this.displayImage = true,
      this.canReturnImageData = false,
      this.canTapHiddenText = false,
      this.hiddenTextColor,
      this.textStyle})
      : assert(onImagePainted == null || displayImage),
        assert(!canReturnImageData || (displayImage && onImagePainted != null)),
        assert(!canTapHiddenText || onLinkTap != null);

  @override
  State<Content> createState() => _ContentState();
}

class _ContentState extends State<Content> {
  HtmlText? _htmlText;

  late final String? _text;

  final List<HiddenText> _hiddenTextList = [];

  bool get _hasHiddenText => _text != null;

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  void _setHiddenText() {
    if (_hasHiddenText) {
      int index = 0;
      _htmlText?.dispose();

      _htmlText = HtmlText(
        context,
        _text!,
        onLinkTap: widget.onLinkTap,
        onText: (context, text) => Regex.onText(text),
        onTextRecursiveParse: true,
        onTags: onHiddenTag(
          (context, element, textStyle) {
            if (widget.canTapHiddenText) {
              late final HiddenText text;
              if (index == _hiddenTextList.length) {
                text = HiddenText();
                _hiddenTextList.add(text);
              } else if (index < _hiddenTextList.length) {
                text = _hiddenTextList[index];
              } else {
                debugPrint('无效的_hiddenTextList index：$index');
                return null;
              }
              index++;

              return getHiddenText(
                context: context,
                element: element,
                textStyle: textStyle,
                hiddenColor: widget.hiddenTextColor,
                getHiddenText: () => text,
                refresh: _refresh,
                onLinkTap: widget.onLinkTap,
              );
            } else {
              return getHiddenText(
                context: context,
                element: element,
                textStyle: textStyle,
                hiddenColor: widget.hiddenTextColor,
              );
            }
          },
        ),
        textStyle: widget.textStyle,
      );
    }
  }

  @override
  void initState() {
    super.initState();

    _text = Regex.replaceHiddenTag(widget.post.content);

    if (!_hasHiddenText) {
      _htmlText = HtmlText(
        context,
        widget.post.content,
        onLinkTap: widget.onLinkTap,
        onText: (context, text) => Regex.onText(text),
        onTextRecursiveParse: true,
        textStyle: widget.textStyle,
      );
    }
  }

  @override
  void dispose() {
    for (final text in _hiddenTextList) {
      text.dispose();
    }
    _htmlText?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    _setHiddenText();

    final richText = RichText(
      text: _htmlText!.toTextSpan(),
      maxLines: widget.maxLines,
      overflow:
          widget.maxLines == null ? TextOverflow.clip : TextOverflow.ellipsis,
    );

    return ValueListenableBuilder<Box>(
      valueListenable: settings.showImageListenable,
      builder: (context, value, child) =>
          (settings.showImage && widget.displayImage && widget.post.hasImage())
              ? FloatColumn(
                  children: [
                    Floatable(
                      float: FCFloat.start,
                      padding: const EdgeInsets.only(right: 5.0),
                      child: ThumbImage(
                        post: widget.post,
                        poUserHash: widget.poUserHash,
                        onImagePainted: widget.onImagePainted,
                        canReturnImageData: widget.canReturnImageData,
                      ),
                    ),
                    richText,
                  ],
                )
              : richText,
    );
  }
}
