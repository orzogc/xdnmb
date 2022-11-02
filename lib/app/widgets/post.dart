import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:html_to_text/html_to_text.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

import '../utils/extensions.dart';
import '../utils/theme.dart';
import '../utils/time.dart';
import 'content.dart';
import 'forum_name.dart';
import 'image.dart';
import 'scroll.dart';
import 'tooltip.dart';

typedef PostGestureCallback = void Function(PostBase post);

class _PostUser extends StatelessWidget {
  final String userHash;

  final String? poUserHash;

  final bool isAdmin;

  const _PostUser(
      {super.key,
      required this.userHash,
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
            : (isPo ? Colors.cyan.shade700 : defaultStyle.style.color),
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
                color: AppTheme.headerColor,
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
          style: const TextStyle(color: AppTheme.headerColor),
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
          style: const TextStyle(color: AppTheme.headerColor),
        ),
      );
}

class _PostSage extends StatelessWidget {
  const _PostSage({super.key});

  @override
  Widget build(BuildContext context) => Row(
        children: const [
          Flexible(child: Text('本串已经被SAGE', style: AppTheme.boldRed)),
          SizedBox(width: 5.0),
          QuestionTooltip('被SAGE的串不会因为新回复而被顶上来，且一定时间后无法回复'),
        ],
      );
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
      : assert((title?.isNotEmpty ?? false) ||
            (name?.isNotEmpty ?? false) ||
            (content?.isNotEmpty ?? false));

  @override
  Widget build(BuildContext context) => Padding(
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
                        linkColor: AppTheme.highlightColor,
                        maxLines: contentMaxLines!,
                      )
                    : Text(content!),
            ],
          ),
        ),
      );
}

class PostContent extends StatelessWidget {
  final PostBase post;

  final bool showFullTime;

  final bool showPostId;

  final bool showForumName;

  final bool showReplyCount;

  final int? contentMaxLines;

  final String? poUserHash;

  final OnLinkTapCallback? onLinkTap;

  final ImageDataCallback? onImagePainted;

  final bool displayImage;

  final bool canReturnImageData;

  final bool canTapHiddenText;

  final Color? hiddenTextColor;

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
      this.onImagePainted,
      this.displayImage = true,
      this.canReturnImageData = false,
      this.canTapHiddenText = false,
      this.hiddenTextColor,
      this.isContentScrollable = false,
      this.onPostIdTap})
      : assert(onImagePainted == null || displayImage),
        assert(!canReturnImageData || (displayImage && onImagePainted != null));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final forumId = post.forumId;
    final replyCount = post.replyCount;
    final isSage = post.isSage;
    final headerTextStyle =
        theme.textTheme.caption?.apply(color: AppTheme.headerColor);

    final content = Content(
      post: post,
      poUserHash: poUserHash,
      maxLines: contentMaxLines,
      onLinkTap: onLinkTap,
      onImagePainted: onImagePainted,
      displayImage: displayImage,
      canReturnImageData: canReturnImageData,
      canTapHiddenText: canTapHiddenText,
      hiddenTextColor: hiddenTextColor,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post is Tip) Text('来自X岛官方的内容', style: headerTextStyle),
          DefaultTextStyle.merge(
            style: headerTextStyle,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: _PostUser(
                    userHash: post.userHash,
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
              ],
            ),
          ),
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

class PostInkWell extends StatelessWidget {
  final PostContent content;

  final PostGestureCallback? onTap;

  final PostGestureCallback? onLongPress;

  final MouseCursor? mouseCursor;

  final Color? hoverColor;

  PostInkWell(
      {super.key,
      required PostBase post,
      bool showFullTime = true,
      bool showPostId = true,
      bool showForumName = true,
      bool showReplyCount = true,
      int? contentMaxLines,
      String? poUserHash,
      OnLinkTapCallback? onLinkTap,
      ImageDataCallback? onImagePainted,
      bool displayImage = true,
      bool canReturnImageData = false,
      bool canTapHiddenText = false,
      Color? hiddenTextColor,
      bool isContentScrollable = false,
      OnPostIdCallback? onPostIdTap,
      this.onTap,
      this.onLongPress,
      this.mouseCursor,
      this.hoverColor})
      : content = PostContent(
            post: post,
            showFullTime: showFullTime,
            showPostId: showPostId,
            showForumName: showForumName,
            showReplyCount: showReplyCount,
            contentMaxLines: contentMaxLines,
            poUserHash: poUserHash,
            onLinkTap: onLinkTap,
            onImagePainted: onImagePainted,
            displayImage: displayImage,
            canReturnImageData: canReturnImageData,
            canTapHiddenText: canTapHiddenText,
            hiddenTextColor: hiddenTextColor,
            isContentScrollable: isContentScrollable,
            onPostIdTap: onPostIdTap);

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap != null ? () => onTap!(content.post) : null,
        onLongPress:
            onLongPress != null ? () => onLongPress!(content.post) : null,
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
