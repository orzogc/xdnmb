import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

import '../data/services/xdnmb_client.dart';
import '../modules/stack_cache.dart';
import '../routes/routes.dart';
import '../utils/exception.dart';
import '../utils/hidden_text.dart';
import '../utils/toast.dart';
import '../utils/url.dart';
import 'post.dart';
import 'reload.dart';

class ReferenceCard extends StatelessWidget {
  final int postId;

  final String? poUserHash;

  const ReferenceCard({super.key, required this.postId, this.poUserHash});

  @override
  Widget build(BuildContext context) {
    final client = XdnmbClientService.to.client;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20.0),
      child: TapToReload(
        builder: (context, child) => FutureBuilder<HtmlReference>(
          future: client.getHtmlReference(postId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.hasData) {
              final mainPostId = snapshot.data?.mainPostId;

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // TODO: onLongPress
                  PostCard(
                    post: snapshot.data!,
                    showForumName: false,
                    showReplyCount: false,
                    poUserHash: poUserHash,
                    onTap: (post) {},
                    onLinkTap: (context, link) =>
                        parseUrl(url: link, poUserHash: poUserHash),
                    onHiddenText: (context, element, textStyle) => onHiddenText(
                        context: context,
                        element: element,
                        textStyle: textStyle,
                        canTap: true,
                        poUserHash: poUserHash),
                    mouseCursor: SystemMouseCursors.basic,
                    hoverColor: Theme.of(context).cardColor,
                    isContentScrollable: true,
                  ),
                  // TODO: 同一主串不跳转
                  if (mainPostId != null)
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: TextButton(
                        // 如果能拿到非主串的主串串号，这里可能会有问题
                        onPressed: () => AppRoutes.toThread(
                            mainPostId: mainPostId, mainPost: snapshot.data!),
                        child: const Text('跳转原串'),
                      ),
                    ),
                ],
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
        tapped: const Text(
          '加载失败，点击重试',
          style: TextStyle(color: Colors.red),
        ),
      ),
    );
  }
}
