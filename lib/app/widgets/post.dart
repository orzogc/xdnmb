import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:html_to_text/html_to_text.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

import '../data/models/tag.dart';
import '../data/services/settings.dart';
import '../data/services/tag.dart';
import '../data/services/time.dart';
import '../data/services/user.dart';
import '../utils/extensions.dart';
import '../utils/text.dart';
import '../utils/theme.dart';
import '../utils/time.dart';
import 'content.dart';
import 'dialog.dart';
import 'forum_name.dart';
import 'listenable.dart';
import 'scroll.dart';
import 'tag.dart';
import 'time.dart';
import 'tooltip.dart';

class _PostUser extends StatelessWidget {
  final String userHash;

  final bool isAdmin;

  final bool isPo;

  final bool showPoTag;

  final TextStyle? textStyle;

  const _PostUser(
      // ignore: unused_element
      {super.key,
      required this.userHash,
      this.isAdmin = false,
      this.isPo = false,
      this.showPoTag = false,
      this.textStyle});

  @override
  Widget build(BuildContext context) {
    final user = UserService.to;
    final settings = SettingsService.to;

    return ListenableBuilder(
      listenable: Listenable.merge([
        if (showPoTag && isPo) settings.showPoCookieTagListenable,
        if (!isAdmin && isPo) settings.poCookieColorListenable,
        settings.showUserCookieNoteListenable,
        if (!isAdmin) settings.showUserCookieColorListenable,
        user.cookieNotifier,
      ]),
      builder: (context, child) {
        TextStyle style = (textStyle ?? AppTheme.postHeaderTextStyle).merge(
          TextStyle(
            color: isAdmin
                ? Colors.red
                : ((settings.showUserCookieColor
                        ? user.getCookieColor(userHash)
                        : null) ??
                    (isPo ? settings.poCookieColor : null)),
          ),
        );
        final fontWeight = style.fontWeight;
        if ((isAdmin || isPo) &&
            (fontWeight == null ||
                fontWeight.toInt() < FontWeight.bold.toInt())) {
          style = style.merge(const TextStyle(fontWeight: FontWeight.bold));
        }

        Widget cookie = htmlToRichText(
          context,
          userHash,
          textStyle: style,
          strutStyle: strutStyleFromHeight(style),
        );

        if (showPoTag && isPo && settings.showPoCookieTag) {
          final tagStyle =
              style.merge(const TextStyle(fontWeight: FontWeight.normal));

          cookie = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Tag(
                text: 'Po',
                textStyle: tagStyle,
                strutStyle: strutStyleFromHeight(tagStyle),
              ),
              const SizedBox(width: 3.0),
              cookie,
            ],
          );
        }

        final String? note =
            settings.showUserCookieNote ? user.getCookieNote(userHash) : null;

        return note != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  cookie,
                  Text(
                    note,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: style,
                    strutStyle: strutStyleFromHeight(style),
                  ),
                ],
              )
            : cookie;
      },
    );
  }
}

class _PostTime extends StatefulWidget {
  final DateTime postTime;

  final bool showFullTime;

  final TextStyle? textStyle;

  const _PostTime(
      // ignore: unused_element
      {super.key,
      required this.postTime,
      this.showFullTime = true,
      this.textStyle});

  @override
  State<_PostTime> createState() => _PostTimeState();
}

class _PostTimeState extends State<_PostTime> {
  @override
  void initState() {
    super.initState();

    final time = TimeService.to;
    if (SettingsService.to.showRelativeTime &&
        widget.postTime.isAfter(time.now)) {
      time.updateTime();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;
    final time = TimeService.to;
    final textStyle = widget.textStyle ?? AppTheme.postHeaderTextStyle;
    final strutStyle = widget.textStyle != null
        ? StrutStyle.fromTextStyle(widget.textStyle!)
        : AppTheme.postHeaderStrutStyle;

    return ListenableBuilder(
      listenable: settings.showRelativeTimeListenable,
      builder: (context, child) => settings.showRelativeTime
          ? TimerRefresher(
              builder: (context) => Text(
                time.relativeTime(widget.postTime),
                style: textStyle,
                strutStyle: strutStyle,
              ),
            )
          : Text(
              widget.showFullTime
                  ? fullFormatTime(widget.postTime)
                  : formatTime(widget.postTime),
              style: textStyle,
              strutStyle: strutStyle,
            ),
    );
  }
}

class _PostId extends StatelessWidget {
  final int postId;

  /// 串号被按时调用，参数是串号
  final ValueSetter<int>? onTapPostId;

  final TextStyle? textStyle;

  const _PostId(
      // ignore: unused_element
      {super.key,
      required this.postId,
      this.onTapPostId,
      this.textStyle});

  @override
  Widget build(BuildContext context) {
    final text = Text(postId.toPostNumber(),
        style: textStyle ?? AppTheme.postHeaderTextStyle,
        strutStyle: textStyle != null
            ? StrutStyle.fromTextStyle(textStyle!)
            : AppTheme.postHeaderStrutStyle);

    return onTapPostId != null
        ? MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => onTapPostId!(postId),
              child: text,
            ),
          )
        : text;
  }
}

class _PostReplyCount extends StatelessWidget {
  final int replyCount;

  final TextStyle? textStyle;

  const _PostReplyCount(
      // ignore: unused_element
      {super.key,
      required this.replyCount,
      this.textStyle});

  @override
  Widget build(BuildContext context) {
    final style = textStyle ?? AppTheme.postHeaderTextStyle;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
            padding: const EdgeInsets.only(top: 2.0, right: 2.0),
            child: Icon(
              Icons.mode_comment_outlined,
              size: style.fontSize != null ? (style.fontSize! + 2.0) : 16.0,
              color: AppTheme.headerColor,
            )),
        Text(
          '$replyCount',
          style: style,
          strutStyle: textStyle != null
              ? StrutStyle.fromTextStyle(textStyle!)
              : AppTheme.postHeaderStrutStyle,
        ),
      ],
    );
  }
}

class _PostTitle extends StatelessWidget {
  final String title;

  final TextStyle? textStyle;

  // ignore: unused_element
  const _PostTitle({super.key, required this.title, this.textStyle});

  @override
  Widget build(BuildContext context) {
    TextStyle spanTextStyle = (textStyle ?? AppTheme.postContentTextStyle);
    final fontWeight = spanTextStyle.fontWeight?.toInt();
    if (fontWeight == null || fontWeight < FontWeight.bold.toInt()) {
      spanTextStyle =
          spanTextStyle.merge(const TextStyle(fontWeight: FontWeight.bold));
    }

    return RichText(
      text: TextSpan(
        text: '标题：',
        children: [
          htmlToTextSpan(
            context,
            title,
            textStyle: spanTextStyle,
          ),
        ],
        style: (textStyle ?? AppTheme.postContentTextStyle).merge(
          const TextStyle(
            color: AppTheme.headerColor,
            fontWeight: FontWeight.normal,
          ),
        ),
      ),
      strutStyle: strutStyleFromHeight(spanTextStyle),
    );
  }
}

class _PostName extends StatelessWidget {
  final String name;

  final TextStyle? textStyle;

  // ignore: unused_element
  const _PostName({super.key, required this.name, this.textStyle});

  @override
  Widget build(BuildContext context) {
    TextStyle spanTextStyle = (textStyle ?? AppTheme.postContentTextStyle);
    final fontWeight = spanTextStyle.fontWeight?.toInt();
    if (fontWeight == null || fontWeight < FontWeight.bold.toInt()) {
      spanTextStyle =
          spanTextStyle.merge(const TextStyle(fontWeight: FontWeight.bold));
    }

    return RichText(
      text: TextSpan(
        text: '名称：',
        children: [
          htmlToTextSpan(
            context,
            name,
            textStyle: spanTextStyle,
          ),
        ],
        style: (textStyle ?? AppTheme.postContentTextStyle).merge(
          const TextStyle(
            color: AppTheme.headerColor,
            fontWeight: FontWeight.normal,
          ),
        ),
      ),
      strutStyle: strutStyleFromHeight(spanTextStyle),
    );
  }
}

class _PostSage extends StatelessWidget {
  final TextStyle? textStyle;

  // ignore: unused_element
  const _PostSage({super.key, this.textStyle});

  @override
  Widget build(BuildContext context) {
    final style = textStyle ?? AppTheme.postContentTextStyle;
    final fontSize = style.fontSize;
    final fontWeight = style.fontWeight;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.ideographic,
      children: [
        Flexible(
            child: Text(
          '本串已经被SAGE',
          style: style.merge(TextStyle(
            color: Colors.red,
            fontWeight: (fontWeight == null ||
                    fontWeight.toInt() < FontWeight.bold.toInt())
                ? FontWeight.bold
                : fontWeight,
          )),
          strutStyle: textStyle != null
              ? StrutStyle.fromTextStyle(textStyle!)
              : AppTheme.postContentStrutStyle,
        )),
        const SizedBox(width: 5.0),
        QuestionTooltip(
          message: '被SAGE的串不会因为新回复而被顶上来，且一定时间后无法回复',
          size: fontSize != null ? (fontSize - 2.0) : null,
        ),
      ],
    );
  }
}

class _PostTagDialog extends StatelessWidget {
  final PostBase post;

  final TagData tag;

  final ValueSetter<int>? onDeleteTag;

  const _PostTagDialog(
      // ignore: unused_element
      {super.key,
      required this.post,
      required this.tag,
      this.onDeleteTag});

  @override
  Widget build(BuildContext context) => SimpleDialog(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (post.isNormalPost) Text(post.toPostNumber()),
            Flexible(child: Tag.fromTagData(tag: tag)),
          ].withSpaceBetween(width: 5.0),
        ),
        children: [
          AddOrReplacePostTag(post: post),
          AddOrEditTag(editedTag: tag),
          AddOrReplacePostTag(post: post, replacedTag: tag),
          DeletePostTag(postId: post.id, tag: tag, onDelete: onDeleteTag),
          ToTaggedPostList(tag.id),
          NewTabToTaggedPostList(tag),
          NewTabBackgroundToTaggedPostList(tag),
        ],
      );
}

class _PostTag extends StatefulWidget {
  final PostBase post;

  final bool isPinned;

  final TextStyle? textStyle;

  final ValueSetter<int>? onDeleteTag;

  const _PostTag(
      // ignore: unused_element
      {super.key,
      required this.post,
      this.isPinned = false,
      this.textStyle,
      this.onDeleteTag});

  @override
  State<_PostTag> createState() => _PostTagState();
}

class _PostTagState extends State<_PostTag> {
  late Stream<List<int>?> _stream;

  PostBase get _post => widget.post;

  void _setStream() =>
      _stream = TagService.getPostTagsIdStream(_post.id).map((event) {
        if (event.isNotEmpty) {
          debugPrint('串 ${_post.toPostNumber()} 有标签');
        }

        return event.isNotEmpty ? event.last : null;
      });

  @override
  void initState() {
    super.initState();

    _setStream();
  }

  @override
  void didUpdateWidget(covariant _PostTag oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.post.id != oldWidget.post.id) {
      _setStream();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tagService = TagService.to;

    return StreamBuilder<List<int>?>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('获取串 ${_post.toPostNumber()} 标签失败：${snapshot.error}');
        }

        if (snapshot.hasData) {
          return ListenableBuilder(
            listenable: tagService.tagListenable(snapshot.data!),
            builder: (context, child) {
              final Widget wrap = Wrap(
                alignment: WrapAlignment.end,
                spacing: 10.0,
                runSpacing: 5.0,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final tag in tagService.getTagsData(snapshot.data!))
                    Tag.fromTagData(
                      tag: tag,
                      textStyle:
                          widget.textStyle ?? AppTheme.postContentTextStyle,
                      strutStyle: widget.textStyle == null
                          ? AppTheme.postContentStrutStyle
                          : null,
                      onTap: () => postListDialog(_PostTagDialog(
                        post: _post,
                        tag: tag,
                        onDeleteTag: widget.onDeleteTag,
                      )),
                    ),
                ],
              );

              return widget.isPinned
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(Icons.push_pin, size: widget.textStyle?.fontSize),
                        const SizedBox(width: 10.0),
                        Flexible(child: wrap),
                      ],
                    )
                  : wrap;
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

class PostDraft extends StatelessWidget {
  final String? title;

  final String? name;

  final String? content;

  final int? contentMaxLines;

  final TextStyle? textStyle;

  PostDraft(
      {super.key,
      this.title,
      this.name,
      this.content,
      this.contentMaxLines,
      TextStyle? textStyle})
      : assert((title?.isNotEmpty ?? false) ||
            (name?.isNotEmpty ?? false) ||
            (content?.isNotEmpty ?? false)),
        textStyle = textStyle != null
            ? SettingsService.to.postContentTextStyle(textStyle)
            : null;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title?.isNotEmpty ?? false)
              _PostTitle(title: title!, textStyle: textStyle),
            if (name?.isNotEmpty ?? false)
              _PostName(name: name!, textStyle: textStyle),
            if (content?.isNotEmpty ?? false)
              contentMaxLines != null
                  ? ExpandableText(
                      content!,
                      expandText: '展开',
                      collapseText: '收起',
                      linkColor: AppTheme.highlightColor,
                      maxLines: contentMaxLines!,
                      style: textStyle ?? AppTheme.postContentTextStyle,
                    )
                  : Text(
                      content!,
                      style: textStyle,
                      strutStyle: textStyle != null
                          ? StrutStyle.fromTextStyle(textStyle!)
                          : AppTheme.postContentStrutStyle,
                    ),
          ],
        ),
      );
}

typedef AttachmentBuilder = Widget Function(TextStyle? textStyle);

class PostContent extends StatelessWidget {
  late final Content content;

  final bool showFullTime;

  final bool showPostId;

  final bool showForumName;

  final bool showReplyCount;

  final bool showPoTag;

  final bool isPinned;

  final double? headerHeight;

  final double? contentMaxHeight;

  /// 串号被按时调用，参数是串号
  final ValueSetter<int>? onTapPostId;

  /// 标签被删除时调用，参数是标签ID
  final ValueSetter<int>? onDeleteTag;

  late final TextStyle? headerTextStyle;

  final AttachmentBuilder? header;

  final AttachmentBuilder? footer;

  PostBase get post => content.post;

  String? get poUserHash => content.poUserHash;

  TextStyle get contentTextStyle => content.textStyle!;

  PostContent(
      {super.key,
      required PostBase post,
      String? poUserHash,
      int? contentMaxLines,
      OnTapLinkCallback? onTapLink,
      ValueSetter<Uint8List>? onPaintImage,
      bool displayImage = true,
      bool canReturnImageData = false,
      bool canTapHiddenText = false,
      Color? hiddenTextColor,
      TextStyle? contentTextStyle,
      OnTextCallback? onText,
      this.showFullTime = true,
      this.showPostId = true,
      this.showForumName = true,
      this.showReplyCount = true,
      this.showPoTag = false,
      this.isPinned = false,
      this.headerHeight,
      this.contentMaxHeight,
      this.onTapPostId,
      this.onDeleteTag,
      TextStyle? headerTextStyle,
      this.header,
      this.footer}) {
    final settings = SettingsService.to;

    this.headerTextStyle = headerTextStyle != null
        ? settings
            .postHeaderTextStyle(headerTextStyle)
            .apply(color: AppTheme.headerColor)
        : null;

    content = Content(
        post: post,
        poUserHash: poUserHash,
        maxLines: contentMaxLines,
        onTapLink: onTapLink,
        onPaintImage: onPaintImage,
        displayImage: displayImage,
        canReturnImageData: canReturnImageData,
        canTapHiddenText: canTapHiddenText,
        hiddenTextColor: hiddenTextColor,
        textStyle: contentTextStyle != null
            ? settings.postContentTextStyle(contentTextStyle)
            : AppTheme.postContentTextStyle,
        onText: onText);
  }

  @override
  Widget build(BuildContext context) {
    final forumId = post.forumId;
    final replyCount = post.replyCount;
    final isSage = post.isSage;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null)
            _PostHeader(
              fontSize:
                  (headerTextStyle ?? AppTheme.postHeaderTextStyle).fontSize,
              height: headerHeight,
              child: header!(headerTextStyle),
            ),
          if (post.isTipType)
            Text(
              '来自X岛匿名版官方的内容',
              style: headerTextStyle ?? AppTheme.postHeaderTextStyle,
              strutStyle: headerTextStyle != null
                  ? StrutStyle.fromTextStyle(headerTextStyle!)
                  : AppTheme.postHeaderStrutStyle,
            ),
          _PostHeader(
            fontSize:
                (headerTextStyle ?? AppTheme.postHeaderTextStyle).fontSize,
            height: headerHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: _PostUser(
                    userHash: post.userHash,
                    isAdmin: post.isAdmin,
                    isPo: post.userHash == poUserHash,
                    showPoTag: showPoTag,
                    textStyle: headerTextStyle,
                  ),
                ),
                Flexible(
                  child: _PostTime(
                    postTime: post.postTime,
                    showFullTime: showFullTime,
                    textStyle: headerTextStyle,
                  ),
                ),
                if (showPostId)
                  _PostId(
                    postId: post.id,
                    onTapPostId: onTapPostId,
                    textStyle: headerTextStyle,
                  ),
                if (showForumName && forumId != null)
                  Flexible(
                    child: ForumName(
                      forumId: forumId,
                      maxLines: 1,
                      textStyle:
                          headerTextStyle ?? AppTheme.postHeaderTextStyle,
                    ),
                  ),
                if (showReplyCount && replyCount != null)
                  _PostReplyCount(
                    replyCount: replyCount,
                    textStyle: headerTextStyle,
                  ),
              ],
            ),
          ),
          if (post.title.isNotEmpty && post.title != '无标题')
            _PostTitle(title: post.title, textStyle: contentTextStyle),
          if (post.name.isNotEmpty && post.name != '无名氏')
            _PostName(name: post.name, textStyle: contentTextStyle),
          if (isSage != null && isSage) _PostSage(textStyle: contentTextStyle),
          if (contentMaxHeight != null)
            ConstrainedBox(
              constraints: BoxConstraints(
                  minWidth: double.infinity, maxHeight: contentMaxHeight!),
              child: SingleChildScrollViewWithScrollbar(child: content),
            )
          else
            content,
          if (!post.isTipType)
            _PostTag(
              post: post,
              isPinned: isPinned,
              textStyle: contentTextStyle,
              onDeleteTag: onDeleteTag,
            ),
          if (footer != null) footer!(headerTextStyle),
        ].withSpaceBetween(height: 5.0),
      ),
    );
  }
}

class PostInkWell extends StatelessWidget {
  final PostContent content;

  /// 按下时调用，参数是被按的串的数据
  final ValueSetter<PostBase>? onTap;

  /// 长按时调用，参数是被按的串的数据
  final ValueSetter<PostBase>? onLongPress;

  final MouseCursor? mouseCursor;

  final Color? hoverColor;

  PostBase get post => content.post;

  PostInkWell(
      {super.key,
      required PostBase post,
      String? poUserHash,
      int? contentMaxLines,
      OnTapLinkCallback? onTapLink,
      ValueSetter<Uint8List>? onPaintImage,
      bool displayImage = true,
      bool canReturnImageData = false,
      bool canTapHiddenText = false,
      Color? hiddenTextColor,
      TextStyle? contentTextStyle,
      OnTextCallback? onText,
      bool showFullTime = true,
      bool showPostId = true,
      bool showForumName = true,
      bool showReplyCount = true,
      bool showPoTag = false,
      bool isPinned = false,
      double? headerHeight,
      double? contentMaxHeight,
      ValueSetter<int>? onTapPostId,
      ValueSetter<int>? onDeleteTag,
      TextStyle? headerTextStyle,
      AttachmentBuilder? header,
      AttachmentBuilder? footer,
      this.onTap,
      this.onLongPress,
      this.mouseCursor,
      this.hoverColor})
      : content = PostContent(
            post: post,
            poUserHash: poUserHash,
            contentMaxLines: contentMaxLines,
            onTapLink: onTapLink,
            onPaintImage: onPaintImage,
            displayImage: displayImage,
            canReturnImageData: canReturnImageData,
            canTapHiddenText: canTapHiddenText,
            hiddenTextColor: hiddenTextColor,
            contentTextStyle: contentTextStyle,
            onText: onText,
            showFullTime: showFullTime,
            showPostId: showPostId,
            showForumName: showForumName,
            showReplyCount: showReplyCount,
            showPoTag: showPoTag,
            isPinned: isPinned,
            headerHeight: headerHeight,
            contentMaxHeight: contentMaxHeight,
            onTapPostId: onTapPostId,
            onDeleteTag: onDeleteTag,
            headerTextStyle: headerTextStyle,
            header: header,
            footer: footer);

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap != null ? () => onTap!(post) : null,
        onLongPress: onLongPress != null ? () => onLongPress!(post) : null,
        mouseCursor: mouseCursor,
        hoverColor: hoverColor,
        child: content,
      );
}

class PostCard extends StatelessWidget {
  final Widget child;

  const PostCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.symmetric(vertical: 5.0),
        elevation: 2.0,
        child: child,
      );
}

class _PostHeader extends StatelessWidget {
  final double? fontSize;

  final double? height;

  final Widget child;

  const _PostHeader(
      // ignore: unused_element
      {super.key,
      this.fontSize,
      this.height,
      required this.child});

  @override
  Widget build(BuildContext context) => fontSize != null
      ? Padding(
          padding: EdgeInsets.symmetric(
              vertical: fontSize! *
                  max(
                      (height ?? SettingsService.to.postHeaderLineHeight) -
                          SettingsService.defaultLineHeight,
                      0.0) *
                  0.5),
          child: child)
      : child;
}
