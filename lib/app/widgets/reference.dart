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

class _ReferenceDialog extends StatelessWidget {
  final PostBase post;

  final int? mainPostId;

  bool get _isMainPost => post.id == mainPostId;

  // ignore: unused_element
  const _ReferenceDialog({super.key, required this.post, this.mainPostId});

  @override
  Widget build(BuildContext context) {
    final PostBase? mainPost = _isMainPost ? post : null;

    return SimpleDialog(
      title: Text(post.id.toPostNumber()),
      children: [
        Report(post.id),
        CopyPostReference(post.id),
        CopyPostContent(post),
        if (mainPostId != null)
          NewTab(
              mainPostId: mainPostId!, mainPost: mainPost, text: '在新标签页打开原串'),
        if (mainPostId != null && !_isMainPost)
          CopyPostReference(mainPostId!, text: '复制原串主串串号引用'),
        if (mainPostId != null)
          NewTabBackground(
              mainPostId: mainPostId!, mainPost: mainPost, text: '在新标签页后台打开原串'),
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
  late Future<ReferenceWithData> _getReference;

  String? errorMessage;

  void _setGetReference() {
    debugPrint('获取串 ${widget.postId.toPostNumber()} 的引用');

    _getReference = XdnmbClientService.to.getHtmlReference(widget.postId);
  }

  @override
  void initState() {
    super.initState();

    _setGetReference();
  }

  @override
  void didUpdateWidget(covariant ReferenceCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.postId != oldWidget.postId) {
      _setGetReference();
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => Card(
          margin: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Padding(
            padding: const EdgeInsets.all(5.0),
            child: FutureBuilder<ReferenceWithData>(
              future: _getReference,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done &&
                    snapshot.hasData) {
                  final referenceData = snapshot.data!;
                  final reference = referenceData.reference;
                  final data = referenceData.data;
                  final mainPostId = data.mainPostId;

                  return ListenableBuilder(
                    listenable:
                        BlacklistService.to.postAndUserBlacklistNotifier,
                    builder: (context, child) {
                      final isVisible = (!reference.isBlocked()).obs;

                      return Obx(
                        () => isVisible.value
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  PostInkWell(
                                    post: reference,
                                    poUserHash: widget.poUserHash,
                                    onLinkTap: (context, link, text) =>
                                        parseUrl(
                                            url: link,
                                            mainPostId: widget.mainPostId,
                                            poUserHash: widget.poUserHash),
                                    canTapHiddenText: true,
                                    showForumName: false,
                                    showReplyCount: false,
                                    showPoTag: true,
                                    contentMaxHeight:
                                        constraints.maxHeight * 0.5,
                                    onTap: (post) {},
                                    onLongPress: (post) => postListDialog(
                                        _ReferenceDialog(
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
                                          page: data.page ?? 1,
                                          jumpToId: (!data.isMainPost &&
                                                  data.page != null)
                                              ? reference.id
                                              : null,
                                          mainPost: reference.id == mainPostId
                                              ? reference
                                              : null,
                                        ),
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
                  // 防止重复出现错误
                  if (error != errorMessage) {
                    showToast(error);
                    errorMessage = error;
                  }

                  return GestureDetector(
                    onTap: () {
                      if (mounted) {
                        setState(() {
                          errorMessage = null;
                          _setGetReference();
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
