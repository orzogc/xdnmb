import 'dart:math';

import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:html_to_text/html_to_text.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

import '../data/services/settings.dart';
import '../data/services/time.dart';
import '../data/services/user.dart';
import '../utils/extensions.dart';
import '../utils/text.dart';
import '../utils/theme.dart';
import '../utils/time.dart';
import 'content.dart';
import 'forum_name.dart';
import 'image.dart';
import 'listenable.dart';
import 'scroll.dart';
import 'tag.dart';
import 'time.dart';
import 'tooltip.dart';

typedef PostGestureCallback = void Function(PostBase post);

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

typedef OnPostIdCallback = void Function(int postId);

class _PostId extends StatelessWidget {
  final int postId;

  final OnPostIdCallback? onPostIdTap;

  final TextStyle? textStyle;

  const _PostId(
      // ignore: unused_element
      {super.key,
      required this.postId,
      this.onPostIdTap,
      this.textStyle});

  @override
  Widget build(BuildContext context) {
    final text = Text(postId.toPostNumber(),
        style: textStyle ?? AppTheme.postHeaderTextStyle,
        strutStyle: textStyle != null
            ? StrutStyle.fromTextStyle(textStyle!)
            : AppTheme.postHeaderStrutStyle);

    return onPostIdTap != null
        ? MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => onPostIdTap!(postId),
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

class PostContent extends StatelessWidget {
  late final Content content;

  final bool showFullTime;

  final bool showPostId;

  final bool showForumName;

  final bool showReplyCount;

  final bool showPoTag;

  final double? headerHeight;

  final double? contentMaxHeight;

  final OnPostIdCallback? onPostIdTap;

  late final TextStyle? headerTextStyle;

  final Widget? footer;

  PostBase get post => content.post;

  String? get poUserHash => content.poUserHash;

  TextStyle get contentTextStyle => content.textStyle!;

  PostContent(
      {super.key,
      required PostBase post,
      String? poUserHash,
      int? contentMaxLines,
      OnLinkTapCallback? onLinkTap,
      ImageDataCallback? onImagePainted,
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
      this.headerHeight,
      this.contentMaxHeight,
      this.onPostIdTap,
      TextStyle? headerTextStyle,
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
        onLinkTap: onLinkTap,
        onImagePainted: onImagePainted,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post is Tip)
            Text(
              '来自X岛匿名版官方的内容',
              style: headerTextStyle ?? AppTheme.postHeaderTextStyle,
              strutStyle: headerTextStyle != null
                  ? StrutStyle.fromTextStyle(headerTextStyle!)
                  : AppTheme.postHeaderStrutStyle,
            ),
          PostHeader(
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
                    onPostIdTap: onPostIdTap,
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
              constraints: BoxConstraints(maxHeight: contentMaxHeight!),
              child: SingleChildScrollViewWithScrollbar(child: content),
            )
          else
            content,
          if (footer != null) footer!,
        ].withSpaceBetween(height: 5.0),
      ),
    );
  }
}

class PostInkWell extends StatelessWidget {
  final PostContent content;

  final PostGestureCallback? onTap;

  final PostGestureCallback? onLongPress;

  final MouseCursor? mouseCursor;

  final Color? hoverColor;

  PostBase get post => content.post;

  PostInkWell(
      {super.key,
      required PostBase post,
      String? poUserHash,
      int? contentMaxLines,
      OnLinkTapCallback? onLinkTap,
      ImageDataCallback? onImagePainted,
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
      double? headerHeight,
      double? contentMaxHeight,
      OnPostIdCallback? onPostIdTap,
      TextStyle? headerTextStyle,
      Widget? footer,
      this.onTap,
      this.onLongPress,
      this.mouseCursor,
      this.hoverColor})
      : content = PostContent(
            post: post,
            poUserHash: poUserHash,
            contentMaxLines: contentMaxLines,
            onLinkTap: onLinkTap,
            onImagePainted: onImagePainted,
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
            headerHeight: headerHeight,
            contentMaxHeight: contentMaxHeight,
            onPostIdTap: onPostIdTap,
            headerTextStyle: headerTextStyle,
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

class PostHeader extends StatelessWidget {
  final double? fontSize;

  final double? height;

  final Widget child;

  const PostHeader(
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
