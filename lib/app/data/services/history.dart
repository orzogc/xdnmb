import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

import '../../utils/directory.dart';
import '../../utils/extensions.dart';
import '../models/controller.dart';
import '../models/history.dart';
import '../models/post.dart';
import '../models/reply.dart';

class PostHistoryService extends GetxService {
  static PostHistoryService get to => Get.find<PostHistoryService>();

  static const String _databaseName = 'history';

  late final Isar _isar;

  final RxBool isReady = false.obs;

  IsarCollection<BrowseHistory> get _browseHistory => _isar.browseHistorys;

  IsarCollection<PostData> get _postData => _isar.postDatas;

  IsarCollection<ReplyData> get _replyData => _isar.replyDatas;

  Future<BrowseHistory?> getBrowseHistory(int postId) =>
      _browseHistory.get(postId);

  Future<int> browseHistoryCount([DateTimeRange? range]) {
    if (range != null) {
      return _browseHistory
          .where()
          .browseTimeBetween(range.start, range.end.addOneDay(),
              includeUpper: false)
          .count();
    } else {
      return _browseHistory.count();
    }
  }

  Future<int> saveBrowseHistory(BrowseHistory history) =>
      _isar.writeTxn(() => _browseHistory.put(history));

  Future<bool> deleteBrowseHistory(int postId) =>
      _isar.writeTxn(() => _browseHistory.delete(postId));

  Future<void> clearBrowseHistory({DateTimeRange? range, Search? search}) =>
      _isar.writeTxn(() async {
        if (range != null || search != null) {
          QueryBuilder<BrowseHistory, BrowseHistory, dynamic> query =
              _browseHistory.where();

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
          await _browseHistory.clear();
        }
      });

  /// 包括start，不包括end
  Future<List<BrowseHistory>> browseHistoryList(
      {int? start, int? end, DateTimeRange? range, Search? search}) {
    assert((search != null && start == null && end == null) ||
        (search == null && start != null && end != null && start <= end));

    QueryBuilder<BrowseHistory, BrowseHistory, dynamic> query =
        _browseHistory.where(sort: Sort.desc);

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

  Future<PostData?> _getPostData(int id) => _postData.get(id);

  Future<int> postDataCount([DateTimeRange? range]) {
    if (range != null) {
      return _postData
          .where()
          .postTimeBetween(range.start, range.end.addOneDay(),
              includeUpper: false)
          .count();
    } else {
      return _postData.count();
    }
  }

  Future<int> savePostData(PostData post) =>
      _isar.writeTxn(() => _postData.put(post));

  Future<bool> deletePostData(int id) =>
      _isar.writeTxn(() => _postData.delete(id));

  Future<void> updatePostData(int id, PostBase post) async {
    final postData = await _getPostData(id);
    if (postData != null) {
      postData.update(post);
      await savePostData(postData);
    } else {
      debugPrint('找不到PostData，id：$id');
    }
  }

  Future<void> clearPostData({DateTimeRange? range, Search? search}) =>
      _isar.writeTxn(() async {
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
  Future<List<PostData>> postDataList(
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

  Future<ReplyData?> _getReplyData(int id) => _replyData.get(id);

  Future<int> replyDataCount([DateTimeRange? range]) {
    if (range != null) {
      return _replyData
          .where()
          .postTimeBetween(range.start, range.end.addOneDay(),
              includeUpper: false)
          .count();
    } else {
      return _replyData.count();
    }
  }

  Future<int> saveReplyData(ReplyData reply) =>
      _isar.writeTxn(() => _replyData.put(reply));

  Future<bool> deleteReplyData(int id) =>
      _isar.writeTxn(() => _replyData.delete(id));

  Future<bool> updateReplyData(
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

  Future<void> clearReplyData({DateTimeRange? range, Search? search}) =>
      _isar.writeTxn(() async {
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
  Future<List<ReplyData>> replyDataList(
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

  @override
  void onInit() async {
    super.onInit();

    _isar = await Isar.open(
        [BrowseHistorySchema, PostDataSchema, ReplyDataSchema],
        directory: databasePath, name: _databaseName, inspector: false);

    isReady.value = true;
    debugPrint('读取历史数据成功');
  }

  @override
  void onClose() async {
    await _isar.close();
    isReady.value = false;

    super.onClose();
  }
}
