import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../../widgets/listenable.dart';
import '../models/forum.dart';
import '../models/hive.dart';

class BlacklistService extends GetxService {
  static final BlacklistService to = Get.find<BlacklistService>();

  late final Box<BlockForumData> _forumBlacklistBox;

  late final Box<int> _postBlacklistBox;

  late final Box<String> _userBlacklistBox;

  late final HashSet<BlockForumData> _forumBlacklist;

  late final HashSet<int> _postBlacklist;

  late final HashSet<String> _userBlacklist;

  final Notifier forumBlacklistNotifier = Notifier();

  final Notifier postAndUserBlacklistNotifier = Notifier();

  final RxBool isReady = false.obs;

  int get forumBlacklistLength => _forumBlacklistBox.length;

  bool hasForum({required int forumId, required int timelineId}) =>
      _forumBlacklist
          .contains(BlockForumData(forumId: forumId, timelineId: timelineId));

  Future<void> clearForumBlacklist() async {
    await _forumBlacklistBox.clear();
    _forumBlacklist.clear();
    forumBlacklistNotifier.notify();
  }

  BlockForumData? blockedForum(int index) => _forumBlacklistBox.getAt(index);

  Future<void> blockForum(
      {required int forumId, required int timelineId}) async {
    final forum = BlockForumData(forumId: forumId, timelineId: timelineId);
    await _forumBlacklistBox.add(forum);
    _forumBlacklist.add(forum);
    forumBlacklistNotifier.notify();
  }

  Future<void> unblockForum(BlockForumData forum) async {
    await forum.delete();
    _forumBlacklist.remove(forum);
    forumBlacklistNotifier.notify();
  }

  int get postBlacklistLength => _postBlacklistBox.length;

  bool hasPost(int postId) => _postBlacklist.contains(postId);

  Future<void> clearPostBlacklist() async {
    await _postBlacklistBox.clear();
    _postBlacklist.clear();
    postAndUserBlacklistNotifier.notify();
  }

  int? blockedPost(int index) => _postBlacklistBox.getAt(index);

  Future<void> blockPost(int postId) async {
    await _postBlacklistBox.put(postId, postId);
    _postBlacklist.add(postId);
    postAndUserBlacklistNotifier.notify();
  }

  Future<void> unblockPost(int postId) async {
    await _postBlacklistBox.delete(postId);
    _postBlacklist.remove(postId);
    postAndUserBlacklistNotifier.notify();
  }

  int get userBlacklistLength => _userBlacklistBox.length;

  bool hasUser(String userHash) => _userBlacklist.contains(userHash);

  Future<void> clearUserBlacklist() async {
    await _userBlacklistBox.clear();
    _userBlacklist.clear();
    postAndUserBlacklistNotifier.notify();
  }

  String? blockedUser(int index) => _userBlacklistBox.getAt(index);

  Future<void> blockUser(String userHash) async {
    await _userBlacklistBox.put(userHash, userHash);
    _userBlacklist.add(userHash);
    postAndUserBlacklistNotifier.notify();
  }

  Future<void> unblockUser(String userHash) async {
    await _userBlacklistBox.delete(userHash);
    _userBlacklist.remove(userHash);
    postAndUserBlacklistNotifier.notify();
  }

  @override
  void onInit() async {
    super.onInit();

    _forumBlacklistBox =
        await Hive.openBox<BlockForumData>(HiveBoxName.forumBlacklist);
    _postBlacklistBox = await Hive.openBox<int>(HiveBoxName.postBlacklist);
    _userBlacklistBox = await Hive.openBox<String>(HiveBoxName.userBlacklist);

    _forumBlacklist = HashSet.of(_forumBlacklistBox.values);
    _postBlacklist = HashSet.of(_postBlacklistBox.values);
    _userBlacklist = HashSet.of(_userBlacklistBox.values);

    isReady.value = true;
    debugPrint('读取黑名单列表成功');
  }

  @override
  void onClose() async {
    forumBlacklistNotifier.dispose();
    postAndUserBlacklistNotifier.dispose();
    await _forumBlacklistBox.close();
    await _postBlacklistBox.close();
    await _userBlacklistBox.close();
    isReady.value = false;

    super.onClose();
  }
}
