import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';

import '../../utils/directory.dart';
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
          .browseTimeBetween(range.start, range.end, includeUpper: false)
          .count();
    } else {
      return _browseHistory.count();
    }
  }

  Future<int> saveBrowseHistory(BrowseHistory history) =>
      _isar.writeTxn(() => _browseHistory.put(history));

  Future<bool> deleteBrowseHistory(int postId) =>
      _isar.writeTxn(() => _browseHistory.delete(postId));

  Future<void> clearBrowseHistory([DateTimeRange? range]) =>
      _isar.writeTxn(() async {
        if (range != null) {
          await _browseHistory
              .where()
              .browseTimeBetween(range.start, range.end, includeUpper: false)
              .deleteAll();
        } else {
          await _browseHistory.clear();
        }
      });

  /// 包括start，不包括end
  Future<List<BrowseHistory>> browseHistoryList(int start, int end,
      [DateTimeRange? range]) {
    assert(start <= end);

    return range != null
        ? _browseHistory
            .where(sort: Sort.desc)
            .browseTimeBetween(range.start, range.end, includeUpper: false)
            .offset(start)
            .limit(end - start)
            .findAll()
        : _browseHistory
            .where(sort: Sort.desc)
            .anyBrowseTime()
            .offset(start)
            .limit(end - start)
            .findAll();
  }

  Future<PostData?> getPostData(int id) => _postData.get(id);

  Future<int> postDataCount([DateTimeRange? range]) {
    if (range != null) {
      return _postData
          .where()
          .postTimeBetween(range.start, range.end, includeUpper: false)
          .count();
    } else {
      return _postData.count();
    }
  }

  Future<int> savePostData(PostData post) =>
      _isar.writeTxn(() => _postData.put(post));

  Future<bool> deletePostData(int id) =>
      _isar.writeTxn(() => _postData.delete(id));

  Future<void> clearPostData([DateTimeRange? range]) =>
      _isar.writeTxn(() async {
        if (range != null) {
          await _postData
              .where()
              .postTimeBetween(range.start, range.end, includeUpper: false)
              .deleteAll();
        } else {
          await _postData.clear();
        }
      });

  /// 包括start，不包括end
  Future<List<PostData>> postDataList(int start, int end,
      [DateTimeRange? range]) {
    assert(start <= end);

    return range != null
        ? _postData
            .where(sort: Sort.desc)
            .postTimeBetween(range.start, range.end, includeUpper: false)
            .offset(start)
            .limit(end - start)
            .findAll()
        : _postData
            .where(sort: Sort.desc)
            .anyPostTime()
            .offset(start)
            .limit(end - start)
            .findAll();
  }

  Future<ReplyData?> getReplyData(int id) => _replyData.get(id);

  Future<int> replyDataCount([DateTimeRange? range]) {
    if (range != null) {
      return _replyData
          .where()
          .postTimeBetween(range.start, range.end, includeUpper: false)
          .count();
    } else {
      return _replyData.count();
    }
  }

  Future<int> saveReplyData(ReplyData reply) =>
      _isar.writeTxn(() => _replyData.put(reply));

  Future<bool> deleteReplyData(int id) =>
      _isar.writeTxn(() => _replyData.delete(id));

  Future<void> clearReplyData([DateTimeRange? range]) =>
      _isar.writeTxn(() async {
        if (range != null) {
          await _replyData
              .where()
              .postTimeBetween(range.start, range.end, includeUpper: false)
              .deleteAll();
        } else {
          await _replyData.clear();
        }
      });

  /// 包括start，不包括end
  Future<List<ReplyData>> replyDataList(int start, int end,
      [DateTimeRange? range]) {
    assert(start <= end);

    return range != null
        ? _replyData
            .where(sort: Sort.desc)
            .postTimeBetween(range.start, range.end, includeUpper: false)
            .offset(start)
            .limit(end - start)
            .findAll()
        : _replyData
            .where(sort: Sort.desc)
            .anyPostTime()
            .offset(start)
            .limit(end - start)
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
