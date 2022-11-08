import 'dart:async';

import 'package:anchor_scroll_controller/anchor_scroll_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

import '../data/models/controller.dart';
import '../data/models/forum.dart';
import '../data/services/blacklist.dart';
import '../data/services/forum.dart';
import '../data/services/persistent.dart';
import '../data/services/settings.dart';
import '../data/services/xdnmb_client.dart';
import '../modules/post_list.dart';
import '../routes/routes.dart';
import '../utils/exception.dart';
import '../utils/extensions.dart';
import '../utils/misc.dart';
import '../utils/navigation.dart';
import '../utils/notify.dart';
import '../utils/text.dart';
import '../utils/theme.dart';
import '../utils/toast.dart';
import 'bilistview.dart';
import 'dialog.dart';
import 'forum_name.dart';
import 'guide.dart';
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
          style: theme.textTheme.bodyText2
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
  Widget build(BuildContext context) => PopupMenuButton(
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
              onTap: () => showForumRuleDialog(controller.id),
              child: const Text('版规'),
            ),
          const PopupMenuItem(onTap: bottomSheet, child: Text('发串')),
        ],
      );
}

class _AddFeed extends StatelessWidget {
  final int postId;

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
        child: Text('订阅', style: Theme.of(context).textTheme.subtitle1),
      );
}

class _BlockForum extends StatelessWidget {
  final ForumTypeController controller;

  final int forumId;

  const _BlockForum(
      {super.key, required this.controller, required this.forumId});

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.subtitle1;

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

  const _ForumDialog({super.key, required this.controller, required this.post});

  @override
  Widget build(BuildContext context) => SimpleDialog(
        title: Text(post.toPostNumber()),
        children: [
          _AddFeed(post.id),
          Report(post.id),
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
  late final StreamSubscription<int> _pageSubscription;

  @override
  void initState() {
    super.initState();

    _pageSubscription =
        widget.controller.listenPage((page) => widget.controller.trySave());
  }

  @override
  void dispose() {
    _pageSubscription.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final client = XdnmbClientService.to.client;
    final forums = ForumListService.to;
    final blacklist = BlacklistService.to;
    final data = PersistentDataService.to;
    final controller = widget.controller;
    final id = controller.id;

    return PostListAnchorRefresher(
      controller: controller,
      builder: (context, anchorController, refresh) =>
          BiListView<ThreadWithPage>(
        key: ValueKey<int>(refresh),
        controller: anchorController,
        initialPage: controller.page,
        // 版块的最大页固定为100
        lastPage:
            controller.isTimeline ? forums.maxPage(id, isTimeline: true) : 100,
        fetch: (page) async {
          ShowCaseWidgetState? showCase;
          final shouldShowGuide = data.showGuide &&
              controller.isTimeline == defaultForum.isTimeline &&
              id == defaultForum.id &&
              page == 1;
          if (shouldShowGuide) {
            showCase = ShowCaseWidget.of(context);
          }

          final threads = controller.isTimeline
              ? (await client.getTimeline(id, page: page))
                  .map((thread) => ThreadWithPage(thread, page))
                  .toList()
              : (await client.getForum(id, page: page))
                  .map((thread) => ThreadWithPage(thread, page))
                  .toList();

          if (shouldShowGuide) {
            Guide.isShowForumGuides = true;
            showCase!.startShowCase(Guide.forumGuides);
          }

          return threads;
        },
        itemBuilder: (context, thread, index) {
          final mainPost = thread.thread.mainPost;

          final Widget item = NotifyBuilder(
            animation: Listenable.merge([
              if (controller.isTimeline) blacklist.forumBlacklistNotifier,
              blacklist.postAndUserBlacklistNotifier,
            ]),
            builder: (context, child) => !((controller.isTimeline &&
                        !mainPost.isAdmin &&
                        blacklist.hasForum(
                            forumId: mainPost.forumId, timelineId: id)) ||
                    mainPost.isBlocked())
                ? AnchorItemWrapper(
                    key: thread.toValueKey(),
                    controller: anchorController,
                    index: thread.toIndex(),
                    child: PostCard(
                      child: PostInkWell(
                        post: mainPost,
                        showFullTime: false,
                        showPostId: false,
                        showForumName: controller.isTimeline,
                        contentMaxLines: 8,
                        poUserHash: mainPost.userHash,
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

          return data.showGuide &&
                  controller.isTimeline == defaultForum.isTimeline &&
                  id == defaultForum.id &&
                  thread.page == 1 &&
                  index == 0
              ? ThreadGuide(item)
              : item;
        },
        noItemsFoundBuilder: (context) => const Center(
          child: Text('没有串', style: AppTheme.boldRed),
        ),
      ),
    );
  }
}
