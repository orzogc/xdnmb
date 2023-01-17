import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

import 'extensions.dart';

class PostWithPage<T extends PostBase> {
  final T post;

  final int page;

  const PostWithPage(this.post, this.page);

  int toIndex() => post.toIndex(page);

  ValueKey<int> toValueKey() => ValueKey<int>(toIndex());

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PostWithPage<T> && post == other.post && page == other.page);

  @override
  int get hashCode => Object.hash(post, page);
}

class ThreadWithPage {
  final ForumThread thread;

  final int page;

  final bool isDuplicated;

  const ThreadWithPage(this.thread, this.page, this.isDuplicated);

  int toIndex() => thread.mainPost.toIndex(page);

  ValueKey<int> toValueKey() => ValueKey<int>(toIndex());

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ThreadWithPage &&
          thread == other.thread &&
          page == other.page &&
          isDuplicated == other.isDuplicated);

  @override
  int get hashCode => Object.hash(thread, page, isDuplicated);
}

class Visible<T> {
  final T item;

  final RxBool _isVisible;

  bool get isVisible => _isVisible.value;

  set isVisible(bool isVisible) => _isVisible.value = isVisible;

  Visible(this.item, [bool isVisible = true]) : _isVisible = isVisible.obs;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Visible<T> &&
          item == other.item &&
          isVisible == other.isVisible);

  @override
  int get hashCode => Object.hash(item, isVisible);
}
