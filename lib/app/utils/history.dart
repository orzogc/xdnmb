import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

import '../data/models/controller.dart';
import '../data/models/history.dart';
import '../data/models/post.dart';
import '../data/models/reply.dart';
import '../data/services/tag.dart';
import 'backup.dart';
import 'extensions.dart';
import 'isar.dart';

abstract class BrowseDataHistory {
  static IsarCollection<BrowseHistory> get _browseData => isar.browseHistorys;

  static Future<BrowseHistory?> getBrowseData(int postId) =>
      _browseData.get(postId);

  static Future<int> browseDataCount([DateTimeRange? range]) => range != null
      ? _browseData
          .where()
          .browseTimeBetween(range.start, range.end.addOneDay(),
              includeUpper: false)
          .count()
      : _browseData.count();

  static Future<int> saveBrowseData(BrowseHistory history) =>
      isar.writeTxn(() => _browseData.put(history
        ..image = ''
        ..imageExtension = ''));

  static Future<bool> deleteBrowseData(int postId) =>
      isar.writeTxn(() => _browseData.delete(postId));

  static Future<void> clearBrowseData({DateTimeRange? range, Search? search}) =>
      isar.writeTxn(() async {
        if (range != null || search != null) {
          QueryBuilder<BrowseHistory, BrowseHistory, dynamic> query =
              _browseData.where();

          if (range != null) {
            query = (query
                    as QueryBuilder<BrowseHistory, BrowseHistory, QWhereClause>)
                .browseTimeBetween(range.start, range.end.addOneDay(),
                    includeUpper: false);
          }

          if (search != null) {
            if (search.useWildcard) {
              query =
                  (query as QueryBuilder<BrowseHistory, BrowseHistory, QFilter>)
                      .filter()
                      .contentMatches('*${search.text}*',
                          caseSensitive: search.caseSensitive);
            } else {
              query =
                  (query as QueryBuilder<BrowseHistory, BrowseHistory, QFilter>)
                      .filter()
                      .contentContains(search.text,
                          caseSensitive: search.caseSensitive);
            }
          }

          (query as QueryBuilder<BrowseHistory, BrowseHistory,
                  QQueryOperations>)
              .deleteAll();
        } else {
          await _browseData.clear();
        }
      });

  /// 包括start，不包括end
  static Future<List<BrowseHistory>> browseDataList(
      {int? start, int? end, DateTimeRange? range, Search? search}) {
    assert((search != null && start == null && end == null) ||
        (search == null && start != null && end != null && start <= end));

    QueryBuilder<BrowseHistory, BrowseHistory, dynamic> query =
        _browseData.where(sort: Sort.desc);

    if (range != null) {
      query =
          (query as QueryBuilder<BrowseHistory, BrowseHistory, QWhereClause>)
              .browseTimeBetween(range.start, range.end.addOneDay(),
                  includeUpper: false);
    } else {
      query = (query as QueryBuilder<BrowseHistory, BrowseHistory, QWhere>)
          .anyBrowseTime();
    }

    if (search != null) {
      if (search.useWildcard) {
        query = (query as QueryBuilder<BrowseHistory, BrowseHistory, QFilter>)
            .filter()
            .contentMatches('*${search.text}*',
                caseSensitive: search.caseSensitive);
      } else {
        query = (query as QueryBuilder<BrowseHistory, BrowseHistory, QFilter>)
            .filter()
            .contentContains(search.text, caseSensitive: search.caseSensitive);
      }
    } else {
      query = (query as QueryBuilder<BrowseHistory, BrowseHistory, QOffset>)
          .offset(start!)
          .limit(end! - start);
    }

    return (query
            as QueryBuilder<BrowseHistory, BrowseHistory, QQueryOperations>)
        .findAll();
  }
}

abstract class PostHistory {
  static IsarCollection<PostData> get _postData => isar.postDatas;

  static Future<PostData?> _getPostData(int id) => _postData.get(id);

  static Future<int> postDataCount([DateTimeRange? range]) => range != null
      ? _postData
          .where()
          .postTimeBetween(range.start, range.end.addOneDay(),
              includeUpper: false)
          .count()
      : _postData.count();

  static Future<int> savePostData(PostData post) =>
      isar.writeTxn(() => _postData.put(post
        ..image = null
        ..imageExtension = null));

  static Future<bool> deletePostData(int id) =>
      isar.writeTxn(() => _postData.delete(id));

  static Future<void> updatePostData(int id, PostBase post) async {
    final postData = await _getPostData(id);
    if (postData != null) {
      postData.update(post);
      await savePostData(postData);
    } else {
      debugPrint('找不到PostData，id：$id');
    }
  }

  static Future<void> clearPostData({DateTimeRange? range, Search? search}) =>
      isar.writeTxn(() async {
        if (range != null || search != null) {
          QueryBuilder<PostData, PostData, dynamic> query = _postData.where();

          if (range != null) {
            query = (query as QueryBuilder<PostData, PostData, QWhereClause>)
                .postTimeBetween(range.start, range.end.addOneDay(),
                    includeUpper: false);
          }

          if (search != null) {
            if (search.useWildcard) {
              query = (query as QueryBuilder<PostData, PostData, QFilter>)
                  .filter()
                  .contentMatches('*${search.text}*',
                      caseSensitive: search.caseSensitive);
            } else {
              query = (query as QueryBuilder<PostData, PostData, QFilter>)
                  .filter()
                  .contentContains(search.text,
                      caseSensitive: search.caseSensitive);
            }
          }

          (query as QueryBuilder<PostData, PostData, QQueryOperations>)
              .deleteAll();
        } else {
          await _postData.clear();
        }
      });

  /// 包括start，不包括end
  static Future<List<PostData>> postDataList(
      {int? start, int? end, DateTimeRange? range, Search? search}) {
    assert((search != null && start == null && end == null) ||
        (search == null && start != null && end != null && start <= end));

    QueryBuilder<PostData, PostData, dynamic> query =
        _postData.where(sort: Sort.desc);

    if (range != null) {
      query = (query as QueryBuilder<PostData, PostData, QWhereClause>)
          .postTimeBetween(range.start, range.end.addOneDay(),
              includeUpper: false);
    } else {
      query = (query as QueryBuilder<PostData, PostData, QWhere>).anyPostTime();
    }

    if (search != null) {
      if (search.useWildcard) {
        query = (query as QueryBuilder<PostData, PostData, QFilter>)
            .filter()
            .contentMatches('*${search.text}*',
                caseSensitive: search.caseSensitive);
      } else {
        query = (query as QueryBuilder<PostData, PostData, QFilter>)
            .filter()
            .contentContains(search.text, caseSensitive: search.caseSensitive);
      }
    } else {
      query = (query as QueryBuilder<PostData, PostData, QOffset>)
          .offset(start!)
          .limit(end! - start);
    }

    return (query as QueryBuilder<PostData, PostData, QQueryOperations>)
        .findAll();
  }
}

abstract class ReplyHistory {
  static IsarCollection<ReplyData> get _replyData => isar.replyDatas;

  static Future<ReplyData?> getReplyData(int id) => _replyData.get(id);

  static Future<int> replyDataCount([DateTimeRange? range]) => range != null
      ? _replyData
          .where()
          .postTimeBetween(range.start, range.end.addOneDay(),
              includeUpper: false)
          .count()
      : _replyData.count();

  static Future<int> saveReplyData(ReplyData reply) =>
      isar.writeTxn(() => _replyData.put(reply
        ..image = null
        ..imageExtension = null));

  static Future<bool> deleteReplyData(int id) =>
      isar.writeTxn(() => _replyData.delete(id));

  static Future<bool> updateReplyData(
      {required int id,
      required PostBase post,
      int? mainPostId,
      int? page}) async {
    final replyData = await getReplyData(id);
    if (replyData != null) {
      replyData.update(post: post, mainPostId: mainPostId, page: page);
      await saveReplyData(replyData);

      return true;
    } else {
      debugPrint('找不到ReplyData，id：$id');

      return false;
    }
  }

  static Future<void> clearReplyData({DateTimeRange? range, Search? search}) =>
      isar.writeTxn(() async {
        if (range != null || search != null) {
          QueryBuilder<ReplyData, ReplyData, dynamic> query =
              _replyData.where();

          if (range != null) {
            query = (query as QueryBuilder<ReplyData, ReplyData, QWhereClause>)
                .postTimeBetween(range.start, range.end.addOneDay(),
                    includeUpper: false);
          }

          if (search != null) {
            if (search.useWildcard) {
              query = (query as QueryBuilder<ReplyData, ReplyData, QFilter>)
                  .filter()
                  .contentMatches('*${search.text}*',
                      caseSensitive: search.caseSensitive);
            } else {
              query = (query as QueryBuilder<ReplyData, ReplyData, QFilter>)
                  .filter()
                  .contentContains(search.text,
                      caseSensitive: search.caseSensitive);
            }
          }

          (query as QueryBuilder<ReplyData, ReplyData, QQueryOperations>)
              .deleteAll();
        } else {
          await _replyData.clear();
        }
      });

  /// 包括start，不包括end
  static Future<List<ReplyData>> replyDataList(
      {int? start, int? end, DateTimeRange? range, Search? search}) {
    assert((search != null && start == null && end == null) ||
        (search == null && start != null && end != null && start <= end));

    QueryBuilder<ReplyData, ReplyData, dynamic> query =
        _replyData.where(sort: Sort.desc);

    if (range != null) {
      query = (query as QueryBuilder<ReplyData, ReplyData, QWhereClause>)
          .postTimeBetween(range.start, range.end.addOneDay(),
              includeUpper: false);
    } else {
      query =
          (query as QueryBuilder<ReplyData, ReplyData, QWhere>).anyPostTime();
    }

    if (search != null) {
      if (search.useWildcard) {
        query = (query as QueryBuilder<ReplyData, ReplyData, QFilter>)
            .filter()
            .contentMatches('*${search.text}*',
                caseSensitive: search.caseSensitive);
      } else {
        query = (query as QueryBuilder<ReplyData, ReplyData, QFilter>)
            .filter()
            .contentContains(search.text, caseSensitive: search.caseSensitive);
      }
    } else {
      query = (query as QueryBuilder<ReplyData, ReplyData, QOffset>)
          .offset(start!)
          .limit(end! - start);
    }

    return (query as QueryBuilder<ReplyData, ReplyData, QQueryOperations>)
        .findAll();
  }

  static Future<HashMap<String, int>> getReplyCount(int mainPostId) async {
    final list = await _replyData
        .filter()
        .mainPostIdEqualTo(mainPostId)
        .userHashProperty()
        .findAll();

    return list.fold<HashMap<String, int>>(HashMap(), (map, userHash) {
      map.update(
        userHash,
        (value) => ++value,
        ifAbsent: () => 1,
      );

      return map;
    });
  }
}

class BrowseDataHistoryRestoreData extends RestoreData {
  static const int _stepNum = 1000;

  static IsarCollection<BrowseHistory> get _browseData =>
      IsarRestoreOperator.backupIsar.browseHistorys;

  @override
  String get title => '浏览历史记录';

  @override
  String get subTitle => '会覆盖和合并现有的浏览历史记录';

  @override
  CommonRestoreOperator? get commonOperator => const IsarRestoreOperator();

  BrowseDataHistoryRestoreData();

  @override
  Future<bool> canRestore(String dir) =>
      IsarRestoreOperator.backupIsarExist(dir);

  @override
  Future<void> restore(String dir) async {
    await IsarRestoreOperator.openIsar();
    final browsePostIdSet = HashSet.of(
        await BrowseDataHistory._browseData.where().idProperty().findAll());

    await IsarRestoreOperator.openBackupIsar();
    final count = await _browseData.count();
    final n = (count / _stepNum).ceil();

    for (var i = 0; i < n; i++) {
      await IsarRestoreOperator.openBackupIsar();
      final posts = await _browseData
          .where()
          .anyId()
          .offset(i * _stepNum)
          .limit(_stepNum)
          .findAll();
      await IsarRestoreOperator.openIsar();
      final existPosts = await BrowseDataHistory._browseData
          .where()
          .anyOf(posts.where((post) => browsePostIdSet.contains(post.id)),
              (query, post) => query.idEqualTo(post.id))
          .findAll();
      final existPostsBrowseTimeMap = HashMap.fromEntries(
          existPosts.map((post) => MapEntry(post.id, post.browseTime)));
      await isar.writeTxn(
          () => BrowseDataHistory._browseData.putAll(posts.where((post) {
                final existPostBrowseTime = existPostsBrowseTimeMap[post.id];
                if (existPostBrowseTime != null &&
                    !existPostBrowseTime.isBefore(post.browseTime)) {
                  return false;
                } else {
                  return true;
                }
              }).toList()));

      progress = min((i + 1) * _stepNum, count) / count;
    }
  }
}

class _PostKey {
  final int forumId;

  final DateTime postTime;

  final String userHash;

  final String? name;

  final String? title;

  final String content;

  const _PostKey(
      {required this.forumId,
      required this.postTime,
      required this.userHash,
      this.name,
      this.title,
      required this.content});

  _PostKey._fromPostData(PostData post)
      : this(
            forumId: post.forumId,
            postTime: post.postTime,
            userHash: post.userHash,
            name: post.name,
            title: post.title,
            content: post.content);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is _PostKey &&
          forumId == other.forumId &&
          postTime == other.postTime &&
          userHash == other.userHash &&
          name == other.name &&
          title == other.title &&
          content == other.content);

  @override
  int get hashCode =>
      Object.hash(forumId, postTime, userHash, name, title, content);
}

class _ReplyKey extends _PostKey {
  final int mainPostId;

  const _ReplyKey(
      {required this.mainPostId,
      required super.forumId,
      required super.postTime,
      required super.userHash,
      super.name,
      super.title,
      required super.content});

  _ReplyKey._fromReplyData(ReplyData reply)
      : this(
            mainPostId: reply.mainPostId,
            forumId: reply.forumId,
            postTime: reply.postTime,
            userHash: reply.userHash,
            name: reply.name,
            title: reply.title,
            content: reply.content);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is _ReplyKey &&
          mainPostId == other.mainPostId &&
          forumId == other.forumId &&
          postTime == other.postTime &&
          userHash == other.userHash &&
          name == other.name &&
          title == other.title &&
          content == other.content);

  @override
  int get hashCode => Object.hash(
      mainPostId, forumId, postTime, userHash, name, title, content);
}

/// 需要在[TagBackupRestore]前面
class PostHistoryRestoreData extends RestoreData {
  static final HashMap<int, int> convertMap = HashMap();

  static const int _stepNum = 1000;

  static IsarCollection<PostData> get _postData =>
      IsarRestoreOperator.backupIsar.postDatas;

  @override
  String get title => '发表的主串记录';

  @override
  CommonRestoreOperator? get commonOperator => const IsarRestoreOperator();

  PostHistoryRestoreData();

  @override
  Future<bool> canRestore(String dir) =>
      IsarRestoreOperator.backupIsarExist(dir);

  @override
  Future<void> restore(String dir) async {
    await IsarRestoreOperator.openIsar();
    int count = await PostHistory._postData.count();
    int n = (count / _stepNum).ceil();
    final normalPostIdSet = HashSet<int>();
    final abnormalPostMap = HashMap<_PostKey, int>();
    for (var i = 0; i < n; i++) {
      final posts = await PostHistory._postData
          .where()
          .anyId()
          .offset(i * _stepNum)
          .limit(_stepNum)
          .findAll();
      for (final post in posts) {
        if (post.postId != null) {
          normalPostIdSet.add(post.postId!);
        } else {
          abnormalPostMap[_PostKey._fromPostData(post)] = post.id;
        }
      }
    }

    await IsarRestoreOperator.openBackupIsar();
    count = await _postData.count();
    n = (count / _stepNum).ceil();
    final toAddNormal = <PostData>[];
    final toAddAbnormalIds = <int>[];
    final toAddAbnormal = <PostData>[];

    for (var i = 0; i < n; i++) {
      await IsarRestoreOperator.openBackupIsar();
      final posts = await _postData
          .where()
          .anyId()
          .offset(i * _stepNum)
          .limit(_stepNum)
          .findAll();

      for (final post in posts) {
        if (post.postId != null) {
          if (!normalPostIdSet.contains(post.postId)) {
            toAddNormal.add(post.copy());
          }
        } else {
          final existId = abnormalPostMap[_PostKey._fromPostData(post)];
          if (existId != null) {
            convertMap[post.id] = existId;
          } else {
            toAddAbnormalIds.add(post.id);
            toAddAbnormal.add(post.copy());
          }
        }
      }

      await IsarRestoreOperator.openIsar();
      final ids = await isar.writeTxn(() async {
        await PostHistory._postData.putAll(toAddNormal);
        return await PostHistory._postData.putAll(toAddAbnormal);
      });
      for (var i = 0; i < toAddAbnormalIds.length; i++) {
        convertMap[toAddAbnormalIds[i]] = ids[i];
      }

      toAddNormal.clear();
      toAddAbnormalIds.clear();
      toAddAbnormal.clear();
      progress = min((i + 1) * _stepNum, count) / count;
    }
  }
}

/// 需要在[TagBackupRestore]前面
class ReplyHistoryRestoreData extends RestoreData {
  static final HashMap<int, int> convertMap = HashMap();

  static const int _stepNum = 1000;

  static IsarCollection<ReplyData> get _replyData =>
      IsarRestoreOperator.backupIsar.replyDatas;

  @override
  String get title => '回串记录';

  @override
  CommonRestoreOperator? get commonOperator => const IsarRestoreOperator();

  ReplyHistoryRestoreData();

  @override
  Future<bool> canRestore(String dir) =>
      IsarRestoreOperator.backupIsarExist(dir);

  @override
  Future<void> restore(String dir) async {
    await IsarRestoreOperator.openIsar();
    int count = await ReplyHistory._replyData.count();
    int n = (count / _stepNum).ceil();
    final normalReplyIdSet = HashSet<int>();
    final abnormalReplyMap = HashMap<_ReplyKey, int>();
    for (var i = 0; i < n; i++) {
      final replies = await ReplyHistory._replyData
          .where()
          .anyId()
          .offset(i * _stepNum)
          .limit(_stepNum)
          .findAll();
      for (final reply in replies) {
        if (reply.postId != null) {
          normalReplyIdSet.add(reply.postId!);
        } else {
          abnormalReplyMap[_ReplyKey._fromReplyData(reply)] = reply.id;
        }
      }
    }

    await IsarRestoreOperator.openBackupIsar();
    count = await _replyData.count();
    n = (count / _stepNum).ceil();
    final toAddNormal = <ReplyData>[];
    final toAddAbnormalIds = <int>[];
    final toAddAbnormal = <ReplyData>[];

    for (var i = 0; i < n; i++) {
      await IsarRestoreOperator.openBackupIsar();
      final replies = await _replyData
          .where()
          .anyId()
          .offset(i * _stepNum)
          .limit(_stepNum)
          .findAll();

      for (final reply in replies) {
        if (reply.postId != null) {
          if (!normalReplyIdSet.contains(reply.postId)) {
            toAddNormal.add(reply.copy());
          }
        } else {
          final existId = abnormalReplyMap[_ReplyKey._fromReplyData(reply)];
          if (existId != null) {
            convertMap[reply.id] = existId;
          } else {
            toAddAbnormalIds.add(reply.id);
            toAddAbnormal.add(reply.copy());
          }
        }
      }

      await IsarRestoreOperator.openIsar();
      final ids = await isar.writeTxn(() async {
        await ReplyHistory._replyData.putAll(toAddNormal);
        return await ReplyHistory._replyData.putAll(toAddAbnormal);
      });
      for (var i = 0; i < toAddAbnormalIds.length; i++) {
        convertMap[toAddAbnormalIds[i]] = ids[i];
      }

      toAddNormal.clear();
      toAddAbnormalIds.clear();
      toAddAbnormal.clear();
      progress = min((i + 1) * _stepNum, count) / count;
    }
  }
}
