import 'dart:async';
import 'dart:collection';

import 'package:anchor_scroll_controller/anchor_scroll_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

import '../data/models/controller.dart';
import '../data/models/forum.dart';
import '../data/services/blacklist.dart';
import '../data/services/forum.dart';
import '../data/services/settings.dart';
import '../data/services/xdnmb_client.dart';
import '../modules/post_list.dart';
import '../routes/routes.dart';
import '../utils/exception.dart';
import '../utils/extensions.dart';
import '../utils/hash.dart';
import '../utils/navigation.dart';
import '../utils/post_list.dart';
import '../utils/text.dart';
import '../utils/theme.dart';
import '../utils/toast.dart';
import '../utils/url.dart';
import 'backdrop.dart';
import 'bilistview.dart';
import 'dialog.dart';
import 'forum_name.dart';
import 'guide.dart';
import 'listenable.dart';
import 'post.dart';
import 'post_list.dart';
import 'reference.dart';

abstract class ForumTypeController extends PostListController {
  @override
  final int id;

  ForumTypeController({required this.id, required int page}) : super(page);

  factory ForumTypeController.fromForumData(
          {required ForumData forum, int page = 1}) =>
      forum.isTimeline
          ? TimelineController(id: forum.id, page: page)
          : ForumController(id: forum.id, page: page);
}

class ForumController extends ForumTypeController {
  @override
  PostListType get postListType => PostListType.forum;

  ForumController({required int id, required int page})
      : super(id: id, page: page);
}

class TimelineController extends ForumTypeController {
  @override
  PostListType get postListType => PostListType.timeline;

  TimelineController({required int id, required int page})
      : super(id: id, page: page);
}

ForumController forumController(Map<String, String?> parameters) =>
    ForumController(
        id: parameters['forumId'].tryParseInt() ?? 0,
        page: parameters['page'].tryParseInt() ?? 1);

TimelineController timelineController(Map<String, String?> parameters) =>
    TimelineController(
        id: parameters['timelineId'].tryParseInt() ?? 0,
        page: parameters['page'].tryParseInt() ?? 1);

class ForumAppBarTitle extends StatelessWidget {
  final ForumTypeController controller;

  const ForumAppBarTitle(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ForumName(
            forumId: controller.id,
            isTimeline: controller.isTimeline,
            isDisplay: false,
            maxLines: 1),
        Text(
          'X岛 nmbxd.com',
          style: theme.textTheme.bodyMedium
              ?.apply(color: theme.colorScheme.onPrimary),
        )
      ],
    );
  }
}

class ForumAppBarPopupMenuButton extends StatelessWidget {
  final ForumTypeController controller;

  const ForumAppBarPopupMenuButton(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final forumId = controller.id;

    return PopupMenuButton(
      itemBuilder: (context) => [
        PopupMenuItem(
          onTap: () => showNoticeDialog(isAutoUpdate: true),
          child: const Text('公告'),
        ),
        PopupMenuItem(
            onTap: () => postListDialog(const Center(
                child: ReferenceCard(postId: 50000001, poUserHash: 'Admin'))),
            child: const Text('岛规')),
        if (controller.isForum)
          PopupMenuItem(
            onTap: () => showForumRuleDialog(forumId),
            child: const Text('版规'),
          ),
        PopupMenuItem(
            onTap: BottomSheetController.editPostController.showEditPost,
            child: const Text('发串')),
        PopupMenuItem(
          onTap: () async {
            final url = Urls.forumUrl(
                forumId: forumId, isTimeline: controller.isTimeline);
            if (url != null) {
              final forumName = ForumListService.to
                  .forumName(forumId, isTimeline: controller.isTimeline);
              if (forumName != null) {
                final name = htmlToPlainText(context, forumName);
                await Clipboard.setData(ClipboardData(text: url));
                showToast('已复制版块 $name 链接');
              } else {
                showToast('未知版块：$forumId');
              }
            } else {
              showToast('未知版块：$forumId');
            }
          },
          child: const Text('分享'),
        ),
      ],
    );
  }
}

class _AddFeed extends StatelessWidget {
  final int postId;

  // ignore: unused_element
  const _AddFeed(this.postId, {super.key});

  @override
  Widget build(BuildContext context) => SimpleDialogOption(
        onPressed: () async {
          postListBack();
          try {
            await XdnmbClientService.to.client
                .addFeed(SettingsService.to.feedId, postId);
            showToast('订阅 ${postId.toPostNumber()} 成功');
          } catch (e) {
            showToast('订阅 ${postId.toPostNumber()} 失败：${exceptionMessage(e)}');
          }
        },
        child: Text('订阅', style: Theme.of(context).textTheme.titleMedium),
      );
}

class _BlockForum extends StatelessWidget {
  final ForumTypeController controller;

  final int forumId;

  const _BlockForum(
      // ignore: unused_element
      {super.key,
      required this.controller,
      required this.forumId});

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.titleMedium;

    return SimpleDialogOption(
      onPressed: () async {
        final result = await postListDialog<bool>(ConfirmCancelDialog(
          contentWidget: ForumName(
              forumId: forumId,
              leading: '确定屏蔽版块 ',
              trailing: ' ？',
              fallbackText: '确定屏蔽版块？',
              textStyle: textStyle,
              maxLines: 1),
          onConfirm: () => postListBack<bool>(result: true),
          onCancel: () => postListBack<bool>(result: false),
        ));

        if (result ?? false) {
          await BlacklistService.to
              .blockForum(forumId: forumId, timelineId: controller.id);

          final forumText = htmlToPlainText(
              Get.context!, ForumListService.to.forumName(forumId) ?? '');
          showToast('屏蔽版块 $forumText');
          postListBack();
        }
      },
      child: Text('屏蔽版块', style: textStyle),
    );
  }
}

class _ForumDialog extends StatelessWidget {
  final ForumTypeController controller;

  final PostBase post;

  // ignore: unused_element
  const _ForumDialog({super.key, required this.controller, required this.post});

  @override
  Widget build(BuildContext context) => SimpleDialog(
        title: Text(post.toPostNumber()),
        children: [
          _AddFeed(post.id),
          Report(post.id),
          SharePost(mainPostId: post.id),
          if (controller.isTimeline && post.forumId != null)
            _BlockForum(controller: controller, forumId: post.forumId!),
          if (!post.isAdmin) BlockPost(postId: post.id),
          if (!post.isAdmin) BlockUser(userHash: post.userHash),
          CopyPostId(post.id),
          CopyPostReference(post.id),
          CopyPostContent(post),
          NewTab(post),
          NewTabBackground(post),
        ],
      );
}

class ForumBody extends StatefulWidget {
  final ForumTypeController controller;

  const ForumBody(this.controller, {super.key});

  @override
  State<ForumBody> createState() => _ForumBodyState();
}

class _ForumBodyState extends State<ForumBody> {
  late StreamSubscription<int> _pageSubscription;

  final HashSet<int> _postIds = intHashSet();

  void _showGuide() {
    if (mounted && SettingsService.shouldShowGuide) {
      final scaffold = Scaffold.of(context);
      final showCase = ShowCaseWidget.of(context);

      WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
        if (mounted) {
          BackdropController.controller.hideBackLayer();
          showHidden();
          scaffold.closeDrawer();
          scaffold.closeEndDrawer();
          await Future.delayed(const Duration(milliseconds: 300));

          Guide.isShowForumGuides = true;
          showCase.startShowCase(Guide.forumGuides);
        }
      });
    }
  }

  void _trySave(int page) => widget.controller.trySave();

  @override
  void initState() {
    super.initState();

    _pageSubscription = widget.controller.listenPage(_trySave);
  }

  @override
  void didUpdateWidget(covariant ForumBody oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller != oldWidget.controller) {
      _pageSubscription.cancel();
      _pageSubscription = widget.controller.listenPage(_trySave);
    }
  }

  @override
  void dispose() {
    _pageSubscription.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final client = XdnmbClientService.to;
    final settings = SettingsService.to;
    final forums = ForumListService.to;
    final blacklist = BlacklistService.to;
    final controller = widget.controller;
    final id = controller.id;

    return PostListScrollView(
      controller: controller,
      onRefresh: _postIds.clear,
      builder: (context, scrollController, refresh) =>
          BiListView<ThreadWithPage>(
        key: ValueKey<int>(refresh),
        scrollController: scrollController,
        postListController: controller,
        initialPage: controller.page,
        // 版块的最大页固定为100
        lastPage:
            controller.isTimeline ? forums.maxPage(id, isTimeline: true) : 100,
        fetch: (page) async {
          final threads = (controller.isTimeline
                  ? await client.getTimeline(id, page: page)
                  : await client.getForum(id, page: page))
              .map((thread) => ThreadWithPage(
                  thread, page, !_postIds.add(thread.mainPost.id)))
              .toList();

          _showGuide();

          return threads;
        },
        itemBuilder: (context, thread, index) {
          final mainPost = thread.thread.mainPost;

          bool isShowed() =>
              !((settings.forbidDuplicatedPosts && thread.isDuplicated) ||
                  (controller.isTimeline &&
                      !mainPost.isAdmin &&
                      blacklist.hasForum(
                          forumId: mainPost.forumId, timelineId: id)) ||
                  mainPost.isBlocked());

          final Widget item = ListenableBuilder(
            listenable: Listenable.merge([
              settings.forbidDuplicatedPostsListenable,
              if (controller.isTimeline) blacklist.forumBlacklistNotifier,
              blacklist.postAndUserBlacklistNotifier,
            ]),
            builder: (context, child) => isShowed()
                ? AnchorItemWrapper(
                    key: thread.toValueKey(),
                    controller: scrollController,
                    index: thread.toIndex(),
                    child: PostCard(
                      child: PostInkWell(
                        post: mainPost,
                        poUserHash: mainPost.userHash,
                        contentMaxLines: 8,
                        showFullTime: false,
                        showPostId: false,
                        showForumName: controller.isTimeline,
                        onTap: (post) => AppRoutes.toThread(
                            mainPostId: mainPost.id, mainPost: mainPost),
                        onLongPress: (post) => postListDialog(
                          _ForumDialog(controller: controller, post: post),
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          );

          return (SettingsService.shouldShowGuide &&
                  index == 0 &&
                  !ThreadGuide.exist)
              ? ThreadGuide(item)
              : item;
        },
        noItemsFoundBuilder: (context) => Center(
          child: Text(
            '没有串',
            style: AppTheme.boldRedPostContentTextStyle,
            strutStyle: AppTheme.boldRedPostContentStrutStyle,
          ),
        ),
        onRefresh: _postIds.clear,
      ),
    );
  }
}
