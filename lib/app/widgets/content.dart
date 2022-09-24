import 'dart:math';

import 'package:float_column/float_column.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:html_to_text/html_to_text.dart';
import 'package:xdnmb/app/utils/hidden_text.dart';
import 'package:xdnmb_api/xdnmb_api.dart' hide Image;

import '../data/services/settings.dart';
import '../utils/regex.dart';
import '../widgets/image.dart';

class TextContent extends StatefulWidget {
  final String text;

  final int? maxLines;

  final OnLinkTapCallback? onLinkTap;

  final OnTagCallback? onHiddenText;

  final OnImageCallback? onImage;

  const TextContent(
      {super.key,
      required this.text,
      this.maxLines,
      this.onLinkTap,
      this.onHiddenText,
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
      Regex.replaceHiddenTag(widget.text) ?? widget.text,
      onLinkTap: widget.onLinkTap,
      // TODO: 解析HTTP链接
      onText: (context, text) => Regex.onReference(text),
      onTextRecursiveParse: true,
      onTags: widget.onHiddenText != null
          ? onHiddenTag(widget.onHiddenText!)
          : null,
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
            widget.maxLines == null ? TextOverflow.clip : TextOverflow.ellipsis,
      );
}

class Content extends StatefulWidget {
  final PostBase post;

  final String? poUserHash;

  final int? maxLines;

  final OnLinkTapCallback? onLinkTap;

  final OnTagCallback? onHiddenText;

  final bool displayImage;

  const Content(
      {super.key,
      required this.post,
      this.poUserHash,
      this.maxLines,
      this.onLinkTap,
      this.onHiddenText,
      this.displayImage = true});

  @override
  State<Content> createState() => _ContentState();
}

class _ContentState extends State<Content> {
  late final HtmlText _htmlText;

  late final bool hasHiddenText;

  @override
  void initState() {
    super.initState();

    final text = Regex.replaceHiddenTag(widget.post.content);
    hasHiddenText = text != null ? true : false;

    _htmlText = HtmlText(
      context,
      text ?? widget.post.content,
      onLinkTap: widget.onLinkTap,
      // TODO: 解析HTTP链接
      onText: (context, text) => Regex.onReference(text),
      onTextRecursiveParse: true,
      onTags: widget.onHiddenText != null
          ? onHiddenTag(widget.onHiddenText!)
          : null,
    );
  }

  @override
  void dispose() {
    _htmlText.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    final richText = RichText(
      text: _htmlText.toTextSpan(),
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
                      child: LayoutBuilder(
                        builder: (context, constraints) => ConstrainedBox(
                          constraints: BoxConstraints(
                              maxWidth: min(constraints.maxWidth / 3.0, 250.0),
                              maxHeight: 250.0),
                          child: ThumbImage(
                              post: widget.post, poUserHash: widget.poUserHash),
                        ),
                      ),
                    ),
                    hasHiddenText ? Floatable(child: richText) : richText,
                  ],
                )
              : richText,
    );
  }
}
