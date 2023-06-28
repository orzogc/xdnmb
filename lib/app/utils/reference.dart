import 'dart:collection';
import 'dart:math';

import 'package:isar/isar.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

import '../data/models/reference.dart';
import 'backup.dart';
import 'isar.dart';

abstract class ReferenceDatabase {
  static IsarCollection<ReferenceData> get _referenceData =>
      isar.referenceDatas;

  static Future<HashMap<int, ReferenceData>> _getReferenceMap(
      Iterable<ReferenceData> references) async {
    final postIds = references.map((reference) => reference.id);
    final posts = await _referenceData
        .where()
        .anyOf(postIds, (query, postId) => query.idEqualTo(postId))
        .findAll();

    return HashMap.fromEntries(posts.map((post) => MapEntry(post.id, post)));
  }

  static Future<void> _addReferences(Iterable<ReferenceData> references,
      [List<ReferenceData>? cacheList]) async {
    if (references.isEmpty) {
      return;
    }

    await isar.writeTxn(() async {
      final map = await _getReferenceMap(references);

      final toAdd = cacheList ?? <ReferenceData>[];
      for (final reference in references) {
        final stored = map[reference.id];
        if (stored != null) {
          if (!stored.isComplete) {
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

  static Future<ReferenceData?> getReference(int postId) =>
      _referenceData.get(postId);

  static Future<ReferenceData> addPost(
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
        if (!stored.isComplete) {
          stored.update(reference);
          await _referenceData.put(stored);
        }
      } else {
        await _referenceData.put(reference);
      }

      return stored ?? reference;
    });
  }

  static Future<void> addForumThreads(Iterable<ForumThread> threads) =>
      _addReferences(ReferenceData.fromForumThreads(threads));

  static Future<void> addThread(Thread thread, int page) =>
      _addReferences(ReferenceData.fromThread(thread, page));

  static Future<void> addFeeds(Iterable<Feed> feeds) =>
      _addReferences(ReferenceData.fromFeeds(feeds));

  static Future<void> addHtmlFeeds(Iterable<HtmlFeed> feeds) =>
      _addReferences(ReferenceData.fromHtmlFeeds(feeds));
}

class ReferencesRestoreData extends RestoreData {
  static const int _stepNum = 10000;

  static IsarCollection<ReferenceData> get _referenceData =>
      IsarRestoreOperator.backupIsar.referenceDatas;

  @override
  String get title => '其他数据';

  @override
  String get subTitle => '恢复其他数据可能会比较慢，建议不恢复，除非刚卸载重装或者清除过应用数据，否则最好不要选这项';

  @override
  CommonRestoreOperator? get commonOperator => const IsarRestoreOperator();

  ReferencesRestoreData();

  @override
  Future<bool> canRestore(String dir) =>
      IsarRestoreOperator.backupIsarExist(dir);

  @override
  Future<void> restore(String dir) async {
    await IsarRestoreOperator.openIsar();
    int count = await ReferenceDatabase._referenceData.count();
    int n = (count / _stepNum).ceil();
    final completedReferences = HashSet<int>();

    for (var i = 0; i < n; i++) {
      final references = await ReferenceDatabase._referenceData
          .where()
          .anyId()
          .offset(i * _stepNum)
          .limit(_stepNum)
          .findAll();
      completedReferences.addAll(references
          .where((reference) => reference.isComplete)
          .map((reference) => reference.id));
    }

    await IsarRestoreOperator.openBackupIsar();
    count = await _referenceData.count();
    n = (count / _stepNum).ceil();
    final cacheList = <ReferenceData>[];

    for (var i = 0; i < n; i++) {
      await IsarRestoreOperator.openBackupIsar();
      final references = await _referenceData
          .where()
          .anyId()
          .offset(i * _stepNum)
          .limit(_stepNum)
          .findAll();
      await IsarRestoreOperator.openIsar();
      await ReferenceDatabase._addReferences(
          references.where(
              (reference) => !completedReferences.contains(reference.id)),
          cacheList);

      cacheList.clear();
      progress = min((i + 1) * _stepNum, count) / count;
    }
  }
}
