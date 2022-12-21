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
import 'listenable.dart';
import 'post.dart';

class _Dialog extends StatelessWidget {
  final PostBase post;

  final int? mainPostId;

  // ignore: unused_element
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
        Report(post.id),
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

class ReferenceCard extends StatefulWidget {
  final int postId;

  /// 引用串的主串ID（非被引用串）
  final int? mainPostId;

  final String? poUserHash;

  const ReferenceCard(
      {super.key, required this.postId, this.mainPostId, this.poUserHash});

  @override
  State<ReferenceCard> createState() => _ReferenceCardState();
}

class _ReferenceCardState extends State<ReferenceCard> {
  late Future<HtmlReference> _getReference;

  Future<HtmlReference> _toGetReference() {
    debugPrint('获取串 ${widget.postId.toPostNumber()} 的引用');

    return XdnmbClientService.to.client.getHtmlReference(widget.postId);
  }

  @override
  void initState() {
    super.initState();

    _getReference = _toGetReference();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => Card(
          margin: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Padding(
            padding: const EdgeInsets.all(5.0),
            child: FutureBuilder<HtmlReference>(
              future: _getReference,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done &&
                    snapshot.hasData) {
                  final post = snapshot.data!;
                  final mainPostId = post.mainPostId;

                  return ListenableBuilder(
                    listenable:
                        BlacklistService.to.postAndUserBlacklistNotifier,
                    builder: (context, child) {
                      final isVisible = (!post.isBlocked()).obs;

                      return Obx(
                        () => isVisible.value
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  PostInkWell(
                                    post: post,
                                    poUserHash: widget.poUserHash,
                                    onLinkTap: (context, link, text) =>
                                        parseUrl(
                                            url: link,
                                            mainPostId: widget.mainPostId,
                                            poUserHash: widget.poUserHash),
                                    canTapHiddenText: true,
                                    showForumName: false,
                                    showReplyCount: false,
                                    contentMaxHeight:
                                        constraints.maxHeight * 0.5,
                                    onTap: (post) {},
                                    onLongPress: (post) => postListDialog(
                                        _Dialog(
                                            post: post,
                                            mainPostId: mainPostId)),
                                    mouseCursor: SystemMouseCursors.basic,
                                    hoverColor: Theme.of(context).cardColor,
                                  ),
                                  if (mainPostId != null &&
                                      mainPostId != widget.mainPostId)
                                    Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: TextButton(
                                        onPressed: () => AppRoutes.toThread(
                                            mainPostId: mainPostId,
                                            mainPost: post.id == mainPostId
                                                ? post
                                                : null),
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
                    },
                  );
                }

                if (snapshot.connectionState == ConnectionState.done &&
                    snapshot.hasError) {
                  final error = exceptionMessage(snapshot.error!);
                  showToast(error);

                  return GestureDetector(
                    onTap: () {
                      if (mounted) {
                        setState(() {
                          _getReference = _toGetReference();
                        });
                      }
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('错误：$error', style: AppTheme.boldRed),
                        const Text('加载失败，点击重试', style: AppTheme.boldRed),
                      ],
                    ),
                  );
                }

                return const CircularProgressIndicator();
              },
            ),
          ),
        ),
      );
}
