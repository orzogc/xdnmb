import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

import '../data/services/forum.dart';
import '../routes/routes.dart';
import '../widgets/dialog.dart';
import '../widgets/reference.dart';
import 'extensions.dart';
import 'regex.dart';
import 'toast.dart';

abstract class Urls {
  static const String appSource = 'https://github.com/orzogc/xdnmb';

  static const String authorSponsor = 'https://afdian.net/a/orzogc';

  static const String xdnmbSponsor = 'https://afdian.net/a/nmbxd';

  static const String appLatestVersion =
      'https://nmb.ovear.info/orzogc/version.json';

  static const String appUpdateMessage =
      'https://nmb.ovear.info/orzogc/message.json';

  static const String appLatestRelease =
      'https://github.com/orzogc/xdnmb/releases/latest';

  static const String appArmeabiv7aApk =
      'https://nmb.ovear.info/orzogc/xdnmb-latest-armeabi-v7a.apk';

  static const String appArm64Apk =
      'https://nmb.ovear.info/orzogc/xdnmb-latest-arm64-v8a.apk';

  static const String appX64Apk =
      'https://nmb.ovear.info/orzogc/xdnmb-latest-x86_64.apk';

  static const String appFullApk =
      'https://nmb.ovear.info/orzogc/xdnmb-latest-full.apk';

  static String? forumUrl(
      {required int forumId, bool isTimeline = false, int? page}) {
    if (isTimeline) {
      return Uri.https(
              XdnmbUrls.xdnmbHost,
              page != null
                  ? '/Forum/timeline/id/$forumId/page/$page.html'
                  : '/Forum/timeline/id/$forumId')
          .toString();
    }

    final forumName = ForumListService.to.forum(forumId)?.name;
    if (forumName == null) {
      return null;
    }

    return Uri.https(XdnmbUrls.xdnmbHost, '/f/$forumName',
            page != null ? {'page': '$page'} : null)
        .toString();
  }

  static String threadUrl(
          {required int mainPostId,
          bool isOnlyPo = false,
          int? page,
          int? postId}) =>
      isOnlyPo
          ? Uri.https(
                  XdnmbUrls.xdnmbHost,
                  page != null
                      ? '/Forum/po/id/$mainPostId/page/$page.html'
                      : '/Forum/po/id/$mainPostId.html',
                  postId != null ? {'r': '$postId'} : null)
              .toString()
          : Uri.https(
                  XdnmbUrls.xdnmbHost,
                  '/t/$mainPostId',
                  (page != null || postId != null)
                      ? {
                          if (page != null) 'page': '$page',
                          if (postId != null) 'r': '$postId',
                        }
                      : null)
              .toString();
}

Future<void> launchURL(String url) async {
  Uri? uri = Uri.tryParse(url);
  if (uri != null) {
    if (uri.host.isEmpty) {
      uri = Uri.tryParse('http://$url');
      if (uri != null && uri.host.isNotEmpty) {
        await launchUri(uri);
      } else {
        debugPrint('无效的链接：$url');
      }
    } else {
      await launchUri(uri);
    }
  } else {
    debugPrint('无效的链接：$url');
  }
}

Future<void> launchUri(Uri uri) async {
  if (uri.host.isNotEmpty) {
    try {
      if (await canLaunchUrl(uri) &&
          await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        debugPrint('打开链接 $uri 成功');
      } else {
        showToast('打开链接 $uri 失败');
      }
    } catch (e) {
      showToast('打开链接 $uri 失败：$e');
    }
  } else {
    debugPrint('无效的链接：$uri');
  }
}

/// [mainPostId]和[poUserHash]为引用串的主串ID和Po饼干（非被引用串）
void parseUrl(
    {required String url, Uri? uri, int? mainPostId, String? poUserHash}) {
  uri ??= Uri.tryParse(url);

  if (uri != null) {
    final host = uri.host;
    final paths = uri.pathSegments;
    final queries = uri.queryParameters;

    if (host.isEmpty) {
      if (paths.isNotEmpty) {
        switch (paths[0]) {
          case PathNames.reference:
            final id = queries['postId'].tryParseInt();
            if (id != null) {
              postListDialog(Center(
                  child: ReferenceCard(
                      postId: id,
                      mainPostId: mainPostId,
                      poUserHash: poUserHash)));
            } else {
              debugPrint('未知的引用链接：$url');
            }
            break;
          default:
            final newUrl = 'http://$url';
            uri = Uri.tryParse(newUrl);
            if (uri?.host.isNotEmpty ?? false) {
              parseUrl(
                  url: newUrl,
                  uri: uri,
                  mainPostId: mainPostId,
                  poUserHash: poUserHash);
            } else {
              _parseXdnmbUrl(url, paths, queries);
            }
        }
      } else {
        debugPrint('未知的链接：$url');
      }
    } else {
      if (Regex.isXdnmbHost(host)) {
        if (paths.isNotEmpty) {
          _parseXdnmbUrl(url, paths, queries);
        }
      } else {
        launchUri(uri);
      }
    }
  } else {
    debugPrint('解析链接失败：$url');
  }
}

Map<String, String> _getParameters(
    List<String> paths, Map<String, String> queries) {
  final parameter = HashMap.of(queries);

  if (paths.isNotEmpty) {
    for (var i = 0; i < paths.length ~/ 2; i++) {
      parameter[Regex.getXdnmbParameter(paths[2 * i]) ?? ''] =
          Regex.getXdnmbParameter(paths[2 * i + 1]) ?? '';
    }
    if (paths.length.isOdd) {
      parameter[Regex.getXdnmbParameter(paths.last) ?? ''] = '';
    }
  }

  return parameter;
}

int? _getId(Map<String, String> parameters) => parameters['id'].tryParseInt();

int? _getPage(Map<String, String> parameters) {
  final page = parameters['page'].tryParseInt();

  return page != null ? max(page, 1) : null;
}

int? _getPostId(Map<String, String> parameters) {
  final postId = parameters['r'].tryParseInt();

  return postId != null ? max(postId, 1) : null;
}

void _parseXdnmbWeb(
    String url, List<String> paths, Map<String, String> queries) {
  if (paths.length >= 2) {
    final parameters =
        _getParameters(paths.getRange(2, paths.length).toList(), queries);

    switch (paths[0]) {
      case 'f':
      case 'F':
        final name = Regex.getXdnmbParameter(paths[1]);
        if (name != null) {
          final forum = ForumListService.to.findForum(name);
          if (forum != null) {
            final page = _getPage(parameters);
            AppRoutes.toForum(forumId: forum.id, page: page ?? 1);
          } else {
            debugPrint('未知的链接：$url');
          }
        } else {
          debugPrint('未知的链接：$url');
        }

        break;
      case 't':
      case 'T':
        final mainPostId = Regex.getXdnmbParameter(paths[1]).tryParseInt();
        if (mainPostId != null) {
          final page = _getPage(parameters);
          final postId = _getPostId(parameters);
          AppRoutes.toThread(
              mainPostId: mainPostId,
              page: page ?? 1,
              cancelAutoJump: page != null && postId == null,
              jumpToId: postId);
        } else {
          debugPrint('未知的链接：$url');
        }

        break;
      default:
        debugPrint('未知的链接：$url');
    }
  } else {
    debugPrint('未知的链接：$url');
  }
}

void _parseXdnmbForum(
    String url, List<String> paths, Map<String, String> queries) {
  if (paths.isNotEmpty) {
    final parameters =
        _getParameters(paths.getRange(1, paths.length).toList(), queries);

    switch (paths[0]) {
      case 'timeline':
      case 'timeline.html':
        final id = _getId(parameters);
        final page = _getPage(parameters);
        AppRoutes.toTimeline(timelineId: id ?? 1, page: page ?? 1);

        break;
      case 'showf':
      case 'showf.html':
        final id = _getId(parameters);
        if (id != null && id > 0) {
          final page = _getPage(parameters);
          AppRoutes.toForum(forumId: id, page: page ?? 1);
        } else {
          debugPrint('未知的链接：$url');
        }

        break;
      case 'thread':
      case 'thread.html':
        final mainPostId = _getId(parameters);
        if (mainPostId != null && mainPostId > 0) {
          final page = _getPage(parameters);
          final postId = _getPostId(parameters);
          AppRoutes.toThread(
              mainPostId: mainPostId,
              page: page ?? 1,
              cancelAutoJump: page != null && postId == null,
              jumpToId: postId);
        } else {
          debugPrint('未知的链接：$url');
        }

        break;
      case 'po':
      case 'po.html':
        final mainPostId = _getId(parameters);
        if (mainPostId != null && mainPostId > 0) {
          final page = _getPage(parameters);
          final postId = _getPostId(parameters);
          AppRoutes.toOnlyPoThread(
              mainPostId: mainPostId,
              page: page ?? 1,
              cancelAutoJump: page != null && postId == null,
              jumpToId: postId);
        } else {
          debugPrint('未知的链接：$url');
        }

        break;
      case 'feed':
      case 'feed.html':
        final page = _getPage(parameters);
        AppRoutes.toFeed(page: page ?? 1);

        break;
      default:
    }
  } else {
    debugPrint('未知的链接：$url');
  }
}

const List<String> _pathRoot = [
  'home',
  'Home',
  'home.html',
  'Home.html',
  'member',
  'Member',
  'member.html',
  'Member.html'
];

void _parseXdnmbUrl(
    String url, List<String> paths, Map<String, String> queries) {
  if (paths.isNotEmpty) {
    switch (paths[0]) {
      case 'home':
      case 'Home':
      case 'home.html':
      case 'Home.html':
        if (paths.length >= 2) {
          if (!_pathRoot.contains(paths[1])) {
            _parseXdnmbUrl(
                url, paths.getRange(1, paths.length).toList(), queries);
          } else {
            debugPrint('未知的链接：$url');
          }
        }

        break;
      case 'f':
      case 'F':
      case 't':
      case 'T':
        _parseXdnmbWeb(url, paths, queries);
        break;
      case 'forum':
      case 'Forum':
        if (paths.length >= 2) {
          _parseXdnmbForum(
              url, paths.getRange(1, paths.length).toList(), queries);
        }

        break;
      case 'member':
      case 'Member':
      case 'member.html':
      case 'Member.html':
        launchURL(url);
        break;
      default:
        debugPrint('未知的链接：$url');
    }
  } else {
    debugPrint('未知的链接：$url');
  }
}
