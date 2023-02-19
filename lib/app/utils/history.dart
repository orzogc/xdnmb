import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

import '../data/models/controller.dart';
import '../data/models/history.dart';
import '../data/models/post.dart';
import '../data/models/reply.dart';
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
      isar.writeTxn(() => _browseData.put(history));

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
      isar.writeTxn(() => _postData.put(post));

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

  static Future<ReplyData?> _getReplyData(int id) => _replyData.get(id);

  static Future<int> replyDataCount([DateTimeRange? range]) => range != null
      ? _replyData
          .where()
          .postTimeBetween(range.start, range.end.addOneDay(),
              includeUpper: false)
          .count()
      : _replyData.count();

  static Future<int> saveReplyData(ReplyData reply) =>
      isar.writeTxn(() => _replyData.put(reply));

  static Future<bool> deleteReplyData(int id) =>
      isar.writeTxn(() => _replyData.delete(id));

  static Future<bool> updateReplyData(
      {required int id,
      required PostBase post,
      int? mainPostId,
      int? page}) async {
    final replyData = await _getReplyData(id);
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
