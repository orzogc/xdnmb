import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

import '../data/services/blacklist.dart';
import '../data/services/xdnmb_client.dart';
import '../routes/routes.dart';
import '../utils/exception.dart';
import '../utils/extensions.dart';
import '../utils/theme.dart';
import '../utils/toast.dart';
import '../utils/url.dart';
import 'dialog.dart';
import 'post.dart';
import 'reload.dart';

class _Dialog extends StatelessWidget {
  final PostBase post;

  final int? mainPostId;

  const _Dialog({super.key, required this.post, this.mainPostId});

  @override
  Widget build(BuildContext context) {
    final PostBase? mainPost = mainPostId != null
        ? (post.id != mainPostId
            ? Post(
                id: mainPostId!,
                forumId: 4,
                replyCount: 0,
                postTime: DateTime.now(),
                userHash: '',
                content: post.content)
            : post)
        : null;

    return SimpleDialog(
      title: Text(post.id.toPostNumber()),
      children: [
        CopyPostId(post.id),
        CopyPostReference(post.id),
        CopyPostContent(post),
        if (mainPost != null && mainPost.id != post.id)
          CopyPostId(mainPost.id, text: '复制原串主串串号'),
        if (mainPost != null && mainPost.id != post.id)
          CopyPostReference(mainPost.id, text: '复制原串主串串号引用'),
        if (mainPost != null) NewTab(mainPost, text: '在新标签页打开原串'),
        if (mainPost != null) NewTabBackground(mainPost, text: '在新标签页后台打开原串'),
      ],
    );
  }
}

class ReferenceCard extends StatelessWidget {
  final int postId;

  /// 引用串的主串ID（非被引用串）
  final int? mainPostId;

  final String? poUserHash;

  const ReferenceCard(
      {super.key, required this.postId, this.mainPostId, this.poUserHash});

  @override
  Widget build(BuildContext context) {
    final client = XdnmbClientService.to.client;
    final blacklist = BlacklistService.to;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: TapToReload(
          builder: (context, child) => FutureBuilder<HtmlReference>(
            future: client.getHtmlReference(postId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done &&
                  snapshot.hasData) {
                final post = snapshot.data!;
                final mainPostId = post.mainPostId;
                final isVisible = (post.isAdmin ||
                        !(blacklist.hasPost(postId) ||
                            blacklist.hasUser(post.userHash)))
                    .obs;

                return Obx(
                  () => isVisible.value
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            PostInkWell(
                              post: post,
                              showForumName: false,
                              showReplyCount: false,
                              poUserHash: poUserHash,
                              onTap: (post) {},
                              onLongPress: (post) => postListDialog(
                                  _Dialog(post: post, mainPostId: mainPostId)),
                              onLinkTap: (context, link, text) => parseUrl(
                                  url: link,
                                  mainPostId: this.mainPostId,
                                  poUserHash: poUserHash),
                              mouseCursor: SystemMouseCursors.basic,
                              hoverColor: Theme.of(context).cardColor,
                              canTapHiddenText: true,
                              isContentScrollable: true,
                            ),
                            if (mainPostId != null &&
                                mainPostId != this.mainPostId)
                              Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: TextButton(
                                  onPressed: () => AppRoutes.toThread(
                                      mainPostId: mainPostId,
                                      mainPost:
                                          post.id == mainPostId ? post : null),
                                  child: const Text('跳转原串'),
                                ),
                              ),
                          ],
                        )
                      : GestureDetector(
                          onTap: () => isVisible.value = true,
                          child: const Text(
                            '本串已被屏蔽，点击查看内容',
                            style: AppTheme.boldRed,
                          ),
                        ),
                );
              }

              if (snapshot.connectionState == ConnectionState.done &&
                  snapshot.hasError) {
                showToast(exceptionMessage(snapshot.error!));

                return child!;
              }

              return const CircularProgressIndicator();
            },
          ),
          tapped: const Text('加载失败，点击重试', style: AppTheme.boldRed),
        ),
      ),
    );
  }
}
