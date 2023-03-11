import 'dart:collection';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:isar/isar.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

import '../../utils/extensions.dart';
import '../../utils/hash.dart';
import '../../utils/isar.dart';
import '../../utils/post.dart';
import '../models/controller.dart';
import '../models/hive.dart';
import '../models/tag.dart';
import '../models/tagged_post.dart';
import 'persistent.dart';

class TagService extends GetxService {
  static final TagService to = Get.find<TagService>();

  static final IsarCollection<TaggedPost> _taggedPostData = isar.taggedPosts;

  static late final HashSet<int> _taggedPostIdSet;

  late final Box<TagData> _tagsBox;

  late int _nextTagId;

  late final HashMap<String, int> _tagsMap;

  final RxBool isReady = false.obs;

  Iterable<int> get allTagsId => _tagsBox.keys.cast<int>();

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

  /// 删除拥有标签[tagId]的串的标签[tagId]
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
              retained.add(post
                ..image = ''
                ..imageExtension = '');
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

  /// 删除串的标签
  ///
  /// 串数据没有任何标签时会被删除
  static Future<void> deletePostTag(int postId, int tagId) =>
      isar.writeTxn(() async {
        final data = await _taggedPostData.get(postId);
        if (data != null) {
          if (data.deleteTag(tagId)) {
            await _taggedPostData.put(data
              ..image = ''
              ..imageExtension = '');
          } else {
            await _taggedPostData.delete(postId);
            _taggedPostIdSet.remove(postId);
          }
        } else {
          debugPrint('要删除标签的串 ${postId.toPostNumber()} 的数据不存在');
        }
      });

  static Future<void> updatePosts(Iterable<PostBase> posts,
      [int? forumId]) async {
    final postMap = intHashMapFromEntries(posts
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

  static Future<void> addFeeds(Iterable<Feed> feeds) => updatePosts(feeds);

  bool tagIdExists(int tagId) => _tagsBox.containsKey(tagId);

  bool tagNameExists(String tagName) => _tagsMap.containsKey(tagName);

  ValueListenable<Box<TagData>> tagListenable(List<int> tagsId) =>
      _tagsBox.listenable(keys: tagsId);

  TagData? getTagData(int tagId) => _tagsBox.get(tagId);

  TagData? getTagDataFromName(String tagName) {
    final tagId = _tagsMap[tagName];

    return tagId != null ? _tagsBox.get(tagId) : null;
  }

  Iterable<TagData> getTagsData(Iterable<int> tagsId) =>
      tagsId.map((tagId) => _tagsBox.get(tagId)).whereType<TagData>();

  /// 返回标签ID，标签不存在则新建标签，已有的标签不做任何改动
  Future<int> getTagIdOrAddNewTag(
      {required String tagName,
      Color? backgroundColor,
      Color? textColor}) async {
    int? tagId = _tagsMap[tagName];
    if (tagId == null) {
      tagId = _nextTagId;
      await _tagsBox.put(
          tagId,
          TagData(
              id: tagId,
              name: tagName,
              backgroundColorValue: backgroundColor?.value,
              textColorValue: textColor?.value));
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
      debugPrint('不存在标签ID：${tag.id}');
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
      debugPrint('不存在标签ID：$tagId');
    }
  }

  /// 添加串的标签
  ///
  /// 数据库里没有[post]的数据时会新建数据
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

        await _taggedPostData.put(data
          ..image = ''
          ..imageExtension = '');
        _taggedPostIdSet.add(post.id);
      });

      PersistentDataService.to.addRecentTag(tagId);
    } else {
      debugPrint('不存在标签ID：$tagId');
    }
  }

  Future<void> replacePostTag(
      {required int postId,
      required int oldTagId,
      required int newTagId}) async {
    if (tagIdExists(newTagId)) {
      await isar.writeTxn(() async {
        final data = await _taggedPostData.get(postId);
        if (data != null) {
          if (data.replaceTag(oldTagId, newTagId)) {
            await _taggedPostData.put(data
              ..image = ''
              ..imageExtension = '');
            PersistentDataService.to.addRecentTag(newTagId);
          }
        } else {
          debugPrint('要替换标签的串 ${postId.toPostNumber()} 的数据不存在');
        }
      });
    } else {
      debugPrint('不存在要替换的标签ID： $newTagId');
    }
  }

  @override
  void onInit() async {
    super.onInit();

    _tagsBox = await Hive.openBox<TagData>(HiveBoxName.tags);
    _nextTagId = _tagsBox.isNotEmpty
        ? _tagsBox.keys.reduce((value, element) => max<int>(value, element)) + 1
        : 0;
    _tagsMap = HashMap.fromEntries(
        _tagsBox.values.map((tag) => MapEntry(tag.name, tag.id)));
    _taggedPostIdSet = intHashSetOf(
        await _taggedPostData.where().anyId().idProperty().findAll());

    isReady.value = true;
    debugPrint('读取标签数据成功');
  }

  @override
  void onClose() {
    isReady.value = false;

    super.onClose();
  }
}
