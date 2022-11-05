import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../models/forum.dart';
import '../models/hive.dart';

class BlacklistService extends GetxService {
  static BlacklistService get to => Get.find<BlacklistService>();

  late final Box<BlockForumData> _forumBlacklistBox;

  late final Box<int> _postBlacklistBox;

  late final Box<String> _userBlacklistBox;

  final RxBool isReady = false.obs;

  late final HashSet<BlockForumData> forumBlacklist;

  late final HashSet<int> postBlacklist;

  late final HashSet<String> userBlacklist;

  int get forumBlacklistLength => _forumBlacklistBox.length;

  bool hasForum(BlockForumData forum) => forumBlacklist.contains(forum);

  Future<void> clearForumBlacklist() async {
    await _forumBlacklistBox.clear();
    forumBlacklist.clear();
  }

  BlockForumData? blockedForum(int index) => _forumBlacklistBox.getAt(index);

  Future<void> blockForum(BlockForumData forum) async {
    await _forumBlacklistBox.add(forum);
    forumBlacklist.add(forum);
  }

  Future<void> unblockForum(BlockForumData forum) async {
    await forum.delete();
    forumBlacklist.remove(forum);
  }

  int get postBlacklistLength => _postBlacklistBox.length;

  bool hasPost(int postId) => postBlacklist.contains(postId);

  Future<void> clearPostBlacklist() async {
    await _postBlacklistBox.clear();
    postBlacklist.clear();
  }

  int? blockedPost(int index) => _postBlacklistBox.getAt(index);

  Future<void> blockPost(int postId) async {
    await _postBlacklistBox.put(postId, postId);
    postBlacklist.add(postId);
  }

  Future<void> unblockPost(int postId) async {
    await _postBlacklistBox.delete(postId);
    postBlacklist.remove(postId);
  }

  int get userBlacklistLength => _userBlacklistBox.length;

  bool hasUser(String userHash) => userBlacklist.contains(userHash);

  Future<void> clearUserBlacklist() async {
    await _userBlacklistBox.clear();
    userBlacklist.clear();
  }

  String? blockedUser(int index) => _userBlacklistBox.getAt(index);

  Future<void> blockUser(String userHash) async {
    await _userBlacklistBox.put(userHash, userHash);
    userBlacklist.add(userHash);
  }

  Future<void> unblockUser(String userHash) async {
    await _userBlacklistBox.delete(userHash);
    userBlacklist.remove(userHash);
  }

  @override
  void onInit() async {
    super.onInit();

    _forumBlacklistBox =
        await Hive.openBox<BlockForumData>(HiveBoxName.forumBlacklist);
    _postBlacklistBox = await Hive.openBox<int>(HiveBoxName.postBlacklist);
    _userBlacklistBox = await Hive.openBox<String>(HiveBoxName.userBlacklist);

    forumBlacklist = HashSet.of(_forumBlacklistBox.values);
    postBlacklist = HashSet.of(_postBlacklistBox.values);
    userBlacklist = HashSet.of(_userBlacklistBox.values);

    isReady.value = true;
    debugPrint('读取黑名单列表成功');
  }

  @override
  void onClose() async {
    await _forumBlacklistBox.close();
    await _postBlacklistBox.close();
    await _userBlacklistBox.close();
    isReady.value = false;

    super.onClose();
  }
}
