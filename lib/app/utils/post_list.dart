import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

import 'extensions.dart';

class PostWithPage {
  final PostBase post;

  final int page;

  const PostWithPage(this.post, this.page);

  int toIndex() => post.toIndex(page);

  ValueKey<int> toValueKey() => ValueKey<int>(toIndex());
}

class ThreadWithPage {
  final ForumThread thread;

  final int page;

  final bool isDuplicated;

  const ThreadWithPage(this.thread, this.page, this.isDuplicated);

  int toIndex() => thread.mainPost.toIndex(page);

  ValueKey<int> toValueKey() => ValueKey<int>(toIndex());
}

class Visible<T> {
  final T item;

  final RxBool _isVisible;

  bool get isVisible => _isVisible.value;

  set isVisible(bool isVisible) => _isVisible.value = isVisible;

  Visible(this.item, [bool isVisible = true]) : _isVisible = isVisible.obs;
}
