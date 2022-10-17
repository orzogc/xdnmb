import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:html_to_text/html_to_text.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

import '../utils/extensions.dart';
import '../utils/theme.dart';
import '../utils/time.dart';
import 'content.dart';
import 'forum_name.dart';
import 'image.dart';
import 'scroll.dart';

typedef PostGestureCallback = void Function(PostBase post);

class _PostUser extends StatelessWidget {
  final String userHash;

  final Color? poTextColor;

  final String? poUserHash;

  final bool isAdmin;

  const _PostUser(
      {super.key,
      required this.userHash,
      required this.poTextColor,
      this.poUserHash,
      this.isAdmin = false});

  @override
  Widget build(BuildContext context) {
    final defaultStyle = DefaultTextStyle.of(context);
    final isPo = userHash == poUserHash;

    return htmlToRichText(
      context,
      userHash,
      textStyle: TextStyle(
        color: isAdmin
            ? Colors.red
            : (isPo ? poTextColor : defaultStyle.style.color),
        fontWeight: isPo ? FontWeight.bold : defaultStyle.style.fontWeight,
      ),
    );
  }
}

class _PostTime extends StatelessWidget {
  final DateTime postTime;

  final bool showFullTime;

  const _PostTime(
      {super.key, required this.postTime, this.showFullTime = true});

  @override
  Widget build(BuildContext context) =>
      Text(showFullTime ? fullFormatTime(postTime) : formatTime(postTime));
}

typedef OnPostIdCallback = void Function(int postId);

class _PostId extends StatelessWidget {
  final int postId;

  final OnPostIdCallback? onPostIdTap;

  const _PostId({super.key, required this.postId, this.onPostIdTap});

  @override
  Widget build(BuildContext context) => MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onPostIdTap != null ? () => onPostIdTap!(postId) : null,
          child: Text(postId.toPostNumber()),
        ),
      );
}

class _PostReplyCount extends StatelessWidget {
  final int replyCount;

  const _PostReplyCount(this.replyCount, {super.key});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
              padding: EdgeInsets.only(top: 3.0, right: 2.0),
              child: Icon(
                Icons.mode_comment_outlined,
                size: 16.0,
                color: PostContent._headerColor,
              )),
          Text('$replyCount')
        ],
      );
}

class _PostTitle extends StatelessWidget {
  final String title;

  const _PostTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) => RichText(
        text: TextSpan(
          text: '标题：',
          children: [
            htmlToTextSpan(
              context,
              title,
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
          style: const TextStyle(color: PostContent._headerColor),
        ),
      );
}

class _PostName extends StatelessWidget {
  final String name;

  const _PostName(this.name, {super.key});

  @override
  Widget build(BuildContext context) => RichText(
        text: TextSpan(
          text: '名称：',
          children: [
            htmlToTextSpan(
              context,
              name,
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
          style: const TextStyle(color: PostContent._headerColor),
        ),
      );
}

// TODO: sage提示
class _PostSage extends StatelessWidget {
  const _PostSage({super.key});

  @override
  Widget build(BuildContext context) =>
      const Text('SAGE', style: AppTheme.boldRed);
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
      this.textStyle})
      : assert(
            (title?.isNotEmpty ?? false) ||
                (name?.isNotEmpty ?? false) ||
                (content?.isNotEmpty ?? false),
            'the post\'s text can\'t be all empty');

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
      child: DefaultTextStyle.merge(
        style: textStyle,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title?.isNotEmpty ?? false) _PostTitle(title!),
            if (name?.isNotEmpty ?? false) _PostName(name!),
            if (content?.isNotEmpty ?? false)
              contentMaxLines != null
                  ? ExpandableText(
                      content!,
                      expandText: '展开',
                      collapseText: '收起',
                      linkColor: Get.isDarkMode
                          ? Colors.white
                          : AppTheme.primaryColorLight,
                      maxLines: contentMaxLines!,
                    )
                  : Text(content!),
          ],
        ),
      ),
    );
  }
}

class PostContent extends StatelessWidget {
  static const Color _headerColor = Colors.grey;

  final PostBase post;

  final bool showFullTime;

  final bool showPostId;

  final bool showForumName;

  final bool showReplyCount;

  final int? contentMaxLines;

  final String? poUserHash;

  final OnLinkTapCallback? onLinkTap;

  final OnTagCallback? onHiddenText;

  final ImageDataCallback? onImagePainted;

  final bool displayImage;

  final bool canReturnImageData;

  final bool isContentScrollable;

  final OnPostIdCallback? onPostIdTap;

  const PostContent(
      {super.key,
      required this.post,
      this.showFullTime = true,
      this.showPostId = true,
      this.showForumName = true,
      this.showReplyCount = true,
      this.contentMaxLines,
      this.poUserHash,
      this.onLinkTap,
      this.onHiddenText,
      this.onImagePainted,
      this.displayImage = true,
      this.canReturnImageData = false,
      this.isContentScrollable = false,
      this.onPostIdTap})
      : assert(onImagePainted == null || displayImage),
        assert(!canReturnImageData || (displayImage && onImagePainted != null));

  @override
  Widget build(BuildContext context) {
    final defaultStyle = DefaultTextStyle.of(context);
    final theme = Theme.of(context);
    final forumId = post.forumId;
    final replyCount = post.replyCount;
    final isSage = post.isSage;

    final content = Content(
      post: post,
      poUserHash: poUserHash,
      maxLines: contentMaxLines,
      onLinkTap: onLinkTap,
      onHiddenText: onHiddenText,
      onImagePainted: onImagePainted,
      displayImage: displayImage,
      canReturnImageData: canReturnImageData,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DefaultTextStyle.merge(
              style: theme.textTheme.caption?.apply(color: _headerColor),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: _PostUser(
                        userHash: post.userHash,
                        poTextColor: defaultStyle.style.color ??
                            defaultStyle.style.foreground?.color,
                        poUserHash: poUserHash,
                        isAdmin: post.isAdmin,
                      ),
                    ),
                    Flexible(
                      child: _PostTime(
                        postTime: post.postTime,
                        showFullTime: showFullTime,
                      ),
                    ),
                    if (showPostId)
                      _PostId(postId: post.id, onPostIdTap: onPostIdTap),
                    if (showForumName && forumId != null)
                      Flexible(child: ForumName(forumId: forumId, maxLines: 1)),
                    if (showReplyCount && replyCount != null)
                      _PostReplyCount(replyCount)
                  ])),
          if (post.title.isNotEmpty && post.title != '无标题')
            _PostTitle(post.title),
          if (post.name.isNotEmpty && post.name != '无名氏') _PostName(post.name),
          if (isSage != null && isSage) const _PostSage(),
          isContentScrollable
              ? ConstrainedBox(
                  constraints: BoxConstraints(
                      minWidth: double.infinity,
                      maxHeight: MediaQuery.of(context).size.height / 2),
                  child: SingleChildScrollViewWithScrollbar(child: content),
                )
              : content,
        ].withSpaceBetween(height: 5.0),
      ),
    );
  }
}

class PostCard extends StatelessWidget {
  final PostBase post;

  final bool showFullTime;

  final bool showPostId;

  final bool showForumName;

  final bool showReplyCount;

  final int? contentMaxLines;

  // TODO: 自定义PO
  final String? poUserHash;

  final PostGestureCallback? onTap;

  final PostGestureCallback? onLongPress;

  final OnLinkTapCallback? onLinkTap;

  final OnTagCallback? onHiddenText;

  final ImageDataCallback? onImagePainted;

  final MouseCursor? mouseCursor;

  final Color? hoverColor;

  final bool displayImage;

  final bool canReturnImageData;

  final bool isContentScrollable;

  final OnPostIdCallback? onPostIdTap;

  const PostCard(
      {super.key,
      required this.post,
      this.showFullTime = true,
      this.showPostId = true,
      this.showForumName = true,
      this.showReplyCount = true,
      this.contentMaxLines,
      this.poUserHash,
      this.onTap,
      this.onLongPress,
      this.onLinkTap,
      this.onHiddenText,
      this.onImagePainted,
      this.mouseCursor,
      this.hoverColor,
      this.displayImage = true,
      this.canReturnImageData = false,
      this.isContentScrollable = false,
      this.onPostIdTap})
      : assert(onImagePainted == null || displayImage),
        assert(!canReturnImageData || (displayImage && onImagePainted != null));

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap != null ? () => onTap!(post) : null,
      onLongPress: onLongPress != null ? () => onLongPress!(post) : null,
      mouseCursor: mouseCursor,
      hoverColor: hoverColor,
      child: PostContent(
        post: post,
        showFullTime: showFullTime,
        showPostId: showPostId,
        showForumName: showForumName,
        showReplyCount: showReplyCount,
        contentMaxLines: contentMaxLines,
        poUserHash: poUserHash,
        onLinkTap: onLinkTap,
        onHiddenText: onHiddenText,
        onImagePainted: onImagePainted,
        displayImage: displayImage,
        canReturnImageData: canReturnImageData,
        isContentScrollable: isContentScrollable,
        onPostIdTap: onPostIdTap,
      ),
    );
  }
}
