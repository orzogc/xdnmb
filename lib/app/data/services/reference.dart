import 'dart:collection';

import 'package:get/get.dart';
import 'package:isar/isar.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

import '../../utils/hash.dart';
import '../../utils/isar.dart';
import '../models/reference.dart';

class ReferenceService extends GetxService {
  static ReferenceService get to => Get.find<ReferenceService>();

  IsarCollection<ReferenceData> get _referenceData => isar.referenceDatas;

  Future<HashMap<int, ReferenceData>> _getReferenceMap(
      Iterable<ReferenceData> references) async {
    final postIds = references.map((reference) => reference.id);
    final posts = await _referenceData
        .where()
        .anyOf(postIds, (query, postId) => query.idEqualTo(postId))
        .findAll();

    return intHashMapFromEntries(posts.map((post) => MapEntry(post.id, post)));
  }

  Future<void> _addReferences(Iterable<ReferenceData> references) async {
    if (references.isEmpty) {
      return;
    }

    await isar.writeTxn(() async {
      final map = await _getReferenceMap(references);

      final toAdd = <ReferenceData>[];
      for (final reference in references) {
        final stored = map[reference.id];
        if (stored != null) {
          if (!stored.isDone) {
            stored.update(reference);
            toAdd.add(stored);
          }
        } else {
          toAdd.add(reference);
        }
      }

      await _referenceData.putAll(toAdd);
    });
  }

  Future<ReferenceData?> getReference(int postId) => _referenceData.get(postId);

  Future<ReferenceData> addPost(
      {required PostBase post,
      int? mainPostId,
      int? accuratePage,
      int? fuzzyPage}) async {
    final reference = ReferenceData.fromPost(
        post: post,
        mainPostId: mainPostId,
        accuratePage: accuratePage,
        fuzzyPage: fuzzyPage);

    return isar.writeTxn(() async {
      final stored = await _referenceData.get(post.id);
      if (stored != null) {
        if (!stored.isDone) {
          stored.update(reference);
          await _referenceData.put(stored);
        }
      } else {
        await _referenceData.put(reference);
      }

      return stored ?? reference;
    });
  }

  Future<void> addForumThreads(Iterable<ForumThread> threads) =>
      _addReferences(ReferenceData.fromForumThreads(threads));

  Future<void> addThread(Thread thread, int page) =>
      _addReferences(ReferenceData.fromThread(thread, page));

  Future<void> addFeeds(Iterable<Feed> feeds) =>
      _addReferences(ReferenceData.fromFeeds(feeds));
}
