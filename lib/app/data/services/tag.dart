import 'dart:collection';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:isar/isar.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

import '../../utils/backup.dart';
import '../../utils/extensions.dart';
import '../../utils/history.dart';
import '../../utils/isar.dart';
import '../../utils/post.dart';
import '../models/controller.dart';
import '../models/hive.dart';
import '../models/post.dart';
import '../models/reply.dart';
import '../models/tag.dart';
import '../models/tagged_post.dart';
import 'persistent.dart';

class TagService extends GetxService {
  static final TagService to = Get.find<TagService>();

  static IsarCollection<TaggedPost> get _taggedPostData => isar.taggedPosts;

  static late final HashSet<int> _taggedPostIdSet;

  late final Box<TagData> _tagsBox;

  late int _nextTagId;

  late final HashMap<String, int> _tagsMap;

  final RxBool isReady = false.obs;

  static QueryBuilder<TaggedPost, TaggedPost, dynamic> _buildQuery(
      {required int tagId, Search? search}) {
    QueryBuilder<TaggedPost, TaggedPost, dynamic> query =
        _taggedPostData.where().tagsElementEqualTo(tagId);

    if (search != null) {
      if (search.useWildcard) {
        query = (query as QueryBuilder<TaggedPost, TaggedPost, QFilter>)
            .filter()
            .contentMatches('*${search.text}*',
                caseSensitive: search.caseSensitive);
      } else {
        query = (query as QueryBuilder<TaggedPost, TaggedPost, QFilter>)
            .filter()
            .contentContains(search.text, caseSensitive: search.caseSensitive);
      }
    }

    return query;
  }

  static Stream<List<List<int>>> getPostTagsIdStream(int postId) =>
      _taggedPostData
          .where()
          .idEqualTo(postId)
          .tagsProperty()
          .watch(fireImmediately: true);

  static Future<int> getTaggedPostCount(int tagId) =>
      _taggedPostData.where().tagsElementEqualTo(tagId).count();

  /// 删除拥有标签 [tagId] 的所有的串的标签 [tagId]
  ///
  /// 串数据没有任何标签时会被删除
  static Future<void> deleteTagInPosts({required int tagId, Search? search}) =>
      isar.writeTxn(() async {
        final list = await (_buildQuery(tagId: tagId, search: search)
                as QueryBuilder<TaggedPost, TaggedPost, QQueryOperations>)
            .findAll();

        if (list.isNotEmpty) {
          final retained = <TaggedPost>[];
          final removed = <int>[];

          for (final post in list) {
            if (post.deleteTag(tagId)) {
              retained.add(post.removeImage());
            } else {
              removed.add(post.id);
            }
          }

          await _taggedPostData.putAll(retained);
          await _taggedPostData.deleteAll(removed);
          _taggedPostIdSet.removeAll(removed);
        }
      });

  static Future<List<TaggedPost>> taggedPostList(
          {required int tagId, Search? search}) =>
      (_buildQuery(tagId: tagId, search: search)
              as QueryBuilder<TaggedPost, TaggedPost, QSortBy>)
          .sortByTaggedTimeDesc()
          .findAll();

  static Future<void> updatePosts(Iterable<PostBase> posts,
      [int? forumId]) async {
    final postMap = HashMap<int, PostBase>.fromEntries(posts
        .where((post) => _taggedPostIdSet.contains(post.id))
        .map((post) => MapEntry(post.id, post)));

    if (postMap.isNotEmpty) {
      await isar.writeTxn(() async {
        final list = await _taggedPostData
            .where()
            .anyOf(postMap.keys, (query, postId) => query.idEqualTo(postId))
            .findAll();

        for (final data in list) {
          final post = postMap[data.id];
          if (post != null) {
            data.update(post, forumId);
          } else {
            debugPrint('不存在串 ${data.toPostNumber()} 的数据');
          }
        }

        await _taggedPostData.putAll(list);
      });
    }
  }

  static Future<void> addForumThreads(Iterable<ForumThread> threads) =>
      updatePosts(threads.fold(
          <PostBase>[],
          (iter, thread) => iter.followedBy(<PostBase>[thread.mainPost]
              .followedBy(thread.recentReplies.map((post) =>
                  PostOverideForumId(post, thread.mainPost.forumId))))));

  static Future<void> addThread(Thread thread, [bool isFirstPage = false]) =>
      updatePosts(
          isFirstPage
              ? [thread.mainPost].followedBy(thread.replies)
              : thread.replies,
          thread.mainPost.forumId);

  static Future<void> addFeeds(Iterable<FeedBase> feeds) => updatePosts(feeds);

  Iterable<int> get allTagsId => _tagsBox.keys.cast<int>();

  Iterable<TagData> get allTagsData => _tagsBox.values;

  int get tagsCount => _tagsBox.length;

  bool tagIdExists(int tagId) => _tagsBox.containsKey(tagId);

  bool tagNameExists(String tagName) => _tagsMap.containsKey(tagName);

  ValueListenable<Box<TagData>> tagListenable(List<int>? tagsId) =>
      _tagsBox.listenable(keys: tagsId);

  TagData? getTagData(int tagId) => _tagsBox.get(tagId);

  TagData? getTagDataFromName(String tagName) {
    final tagId = _tagsMap[tagName];

    return tagId != null ? _tagsBox.get(tagId) : null;
  }

  Iterable<TagData> getTagsData(Iterable<int> tagsId) =>
      tagsId.map((tagId) => _tagsBox.get(tagId)).whereType<TagData>();

  /// 返回标签 ID，标签不存在则新建标签，已有的标签不做任何改动
  Future<int> getTagIdOrAddNewTag(
      {required String tagName,
      Color? backgroundColor,
      Color? textColor,
      List<int>? pinnedPosts}) async {
    int? tagId = _tagsMap[tagName];
    if (tagId == null) {
      tagId = _nextTagId;
      await _tagsBox.put(
          tagId,
          TagData(
              id: tagId,
              name: tagName,
              backgroundColorValue: backgroundColor?.value,
              textColorValue: textColor?.value,
              pinnedPosts: pinnedPosts ?? <int>[]));
      _tagsMap[tagName] = tagId;
      _nextTagId++;
      PersistentDataService.to.addRecentTag(tagId);
    }

    return tagId;
  }

  /// 修改成功返回`true`，修改失败返回`false`，失败原因通常是标签名重复
  Future<bool> editTag(TagData tag) async {
    final oldTagName = _tagsBox.get(tag.id)?.name;

    if (oldTagName != null) {
      if (tag.name != oldTagName && tagNameExists(tag.name)) {
        return false;
      }

      await _tagsBox.put(tag.id, tag);
      if (tag.name != oldTagName) {
        _tagsMap.remove(oldTagName);
        _tagsMap[tag.name] = tag.id;
      }
      PersistentDataService.to.addRecentTag(tag.id);

      return true;
    } else {
      debugPrint('不存在标签 ID：${tag.id}');
    }

    return false;
  }

  /// 删除标签
  ///
  /// 串数据没有任何标签时会被删除
  Future<void> deleteTag(int tagId) async {
    await deleteTagInPosts(tagId: tagId);

    final tag = _tagsBox.get(tagId);
    if (tag != null) {
      await _tagsBox.delete(tagId);
      _tagsMap.remove(tag.name);
      PersistentDataService.to.deleteRecentTag(tagId);
    } else {
      debugPrint('不存在标签 ID：$tagId');
    }
  }

  /// 添加串的标签
  ///
  /// 数据库里没有 [post] 的数据时会新建数据
  Future<void> addPostTag(PostBase post, int tagId, [int? forumId]) async {
    if (tagIdExists(tagId)) {
      await isar.writeTxn(() async {
        TaggedPost? data = await _taggedPostData.get(post.id);
        if (data != null) {
          data.update(post, forumId);
          data.addTag(tagId);
        } else {
          data =
              TaggedPost.fromPost(post: post, forumId: forumId, tags: [tagId]);
        }

        await _taggedPostData.put(data.removeImage());
        _taggedPostIdSet.add(post.id);
      });

      PersistentDataService.to.addRecentTag(tagId);
    } else {
      debugPrint('不存在标签 ID：$tagId');
    }
  }

  /// 删除串的标签
  ///
  /// 串数据没有任何标签时会被删除
  Future<void> deletePostTag({required int postId, required int tagId}) async {
    await isar.writeTxn(() async {
      final data = await _taggedPostData.get(postId);
      if (data != null) {
        if (data.deleteTag(tagId)) {
          await _taggedPostData.put(data.removeImage());
        } else {
          await _taggedPostData.delete(postId);
          _taggedPostIdSet.remove(postId);
        }
      } else {
        debugPrint('要删除标签的串 ${postId.toPostNumber()} 的数据不存在');
      }
    });

    await unpinPost(postId: postId, tagId: tagId);
  }

  Future<void> replacePostTag(
      {required int postId,
      required int oldTagId,
      required int newTagId}) async {
    if (oldTagId != newTagId) {
      if (tagIdExists(newTagId)) {
        await isar.writeTxn(() async {
          final data = await _taggedPostData.get(postId);
          if (data != null) {
            if (data.replaceTag(oldTagId, newTagId)) {
              await _taggedPostData.put(data.removeImage());
              PersistentDataService.to.addRecentTag(newTagId);
            }
          } else {
            debugPrint('要替换标签的串 ${postId.toPostNumber()} 的数据不存在');
          }
        });

        await unpinPost(postId: postId, tagId: oldTagId);
      } else {
        debugPrint('不存在要替换的标签 ID： $newTagId');
      }
    }
  }

  Future<void> pinPost({required int postId, required int tagId}) async =>
      await getTagData(tagId)?.pinPost(postId);

  Future<void> unpinPost({required int postId, required int tagId}) async =>
      await getTagData(tagId)?.unpinPost(postId);

  @override
  void onInit() async {
    super.onInit();

    _tagsBox = await Hive.openBox<TagData>(HiveBoxName.tags);
    _nextTagId = _tagsBox.isNotEmpty
        ? _tagsBox.keys.reduce((value, element) => max<int>(value, element)) + 1
        : 0;
    _tagsMap = HashMap.fromEntries(
        _tagsBox.values.map((tag) => MapEntry(tag.name, tag.id)));
    _taggedPostIdSet =
        HashSet.of(await _taggedPostData.where().idProperty().findAll());

    isReady.value = true;
    debugPrint('读取标签数据成功');
  }

  @override
  void onClose() async {
    await _tagsBox.close();
    isReady.value = false;

    super.onClose();
  }
}

abstract class TagBackupRestore {
  static final HashMap<int, int> _tagIdConvertMap = HashMap();

  static Future<void> backupHiveTagData(String dir) async {
    await TagService.to._tagsBox.close();

    await copyHiveFileToBackupDir(dir, HiveBoxName.tags);
  }

  // 需要考虑 convertMap 由于发串和回复记录没恢复的情况
  static int? _convertPostId(int postId) {
    if (postId.isNormalPost) {
      return postId;
    } else if (postId.isPostHistory) {
      final newId = PostHistoryRestoreData.convertMap[postId.historyId!];

      return newId != null ? PostData.getTaggedPostId(newId) : null;
    } else if (postId.isReplyHistory) {
      final newId = ReplyHistoryRestoreData.convertMap[postId.historyId!];

      return newId != null ? ReplyData.getTaggedPostId(newId) : null;
    }

    debugPrint('未知的 postId：$postId');
    return null;
  }

  static List<int> _convertPostIds(List<int> postIds) {
    final list = <int>[];
    for (final postId in postIds) {
      final newId = _convertPostId(postId);
      if (newId != null) {
        list.add(newId);
      } else {
        debugPrint('无法获取新的 taggedPostId');
      }
    }

    return list;
  }

  static Future<void> _restoreHiveTagData(String dir) async {
    final tagService = TagService.to;

    final file = await copyHiveBackupFile(dir, HiveBoxName.tags);
    final box = await Hive.openBox<TagData>(hiveBackupName(HiveBoxName.tags));
    for (final tag in box.values) {
      final tagData = tagService.getTagDataFromName(tag.name);
      if (tagData != null) {
        final newTagData = tagData.copyWith(
            backgroundColor: tag.backgroundColor, textColor: tag.textColor);
        for (final postId in _convertPostIds(tag.pinnedPosts)) {
          await newTagData.pinPost(postId, false);
        }
        if (!await tagService.editTag(newTagData)) {
          throw '保存新的 TagData 失败';
        }
        _tagIdConvertMap[tag.id] = newTagData.id;
      } else {
        final newTagId = await tagService.getTagIdOrAddNewTag(
            tagName: tag.name,
            backgroundColor: tag.backgroundColor,
            textColor: tag.textColor,
            pinnedPosts: _convertPostIds(tag.pinnedPosts));
        _tagIdConvertMap[tag.id] = newTagId;
      }
    }

    await box.close();
    await file.delete();
    await deleteHiveBackupLockFile(HiveBoxName.tags);
  }
}

class TagRestoreData extends RestoreData {
  static const int _stepNum = 1000;

  static IsarCollection<TaggedPost> get _taggedPostData =>
      IsarRestoreOperator.backupIsar.taggedPosts;

  @override
  String get title => '标签';

  @override
  String get subTitle => '会覆盖和合并现有标签';

  @override
  CommonRestoreOperator? get commonOperator => const IsarRestoreOperator();

  TagRestoreData();

  TaggedPost _convertTags(TaggedPost post) {
    final newTags = <int>[];
    for (final tagId in post.tags) {
      final newTagId = TagBackupRestore._tagIdConvertMap[tagId];
      if (newTagId != null) {
        newTags.add(newTagId);
      } else {
        debugPrint('无法获取新的标签 ID');
      }
    }

    return post..tags = newTags;
  }

  @override
  Future<bool> canRestore(String dir) async =>
      await hiveBackupFileInDir(dir, HiveBoxName.tags).exists() &&
      await IsarRestoreOperator.backupIsarExist(dir);

  @override
  Future<void> restore(String dir) async {
    await TagBackupRestore._restoreHiveTagData(dir);

    await IsarRestoreOperator.openBackupIsar();
    final count = await _taggedPostData.count();
    final n = (count / _stepNum).ceil();
    final existPostIds = <int>[];
    final newPosts = <TaggedPost>[];

    for (var i = 0; i < n; i++) {
      await IsarRestoreOperator.openBackupIsar();
      final posts = await _taggedPostData
          .where()
          .anyId()
          .offset(i * _stepNum)
          .limit(_stepNum)
          .findAll();

      for (final post in posts) {
        if (post.id.isNormalPost) {
          if (TagService._taggedPostIdSet.contains(post.id)) {
            existPostIds.add(post.id);
          }
          newPosts.add(post);
        } else {
          final newId = TagBackupRestore._convertPostId(post.id);
          if (newId != null) {
            if (TagService._taggedPostIdSet.contains(newId)) {
              existPostIds.add(newId);
            }
            newPosts.add(post.copyWithId(newId));
          } else {
            debugPrint('无法获取新的 ID');
          }
        }
      }

      await IsarRestoreOperator.openIsar();
      final existPosts = await TagService._taggedPostData
          .where()
          .anyOf(existPostIds, (query, postId) => query.idEqualTo(postId))
          .findAll();
      final existPostsMap = HashMap.fromEntries(
          existPosts.map((post) => MapEntry(post.id, post)));

      final toAddPosts = newPosts.map((post) {
        post = _convertTags(post);
        final existPost = existPostsMap[post.id];
        if (existPost != null) {
          existPost.updateTags(post);

          return existPost.removeImage();
        } else {
          return post.removeImage();
        }
      }).toList();
      await isar.writeTxn(() => TagService._taggedPostData.putAll(toAddPosts));

      existPostIds.clear();
      newPosts.clear();
      progress = min((i + 1) * _stepNum, count) / count;
    }
  }
}
