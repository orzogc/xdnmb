import 'package:flutter/material.dart';

import '../modules/post_list.dart';

ValueKey<PostListKey> getPostListKey(PostList postList, int refresh) =>
    ValueKey(PostListKey(postList, refresh));

class PostListKey {
  final PostList postList;

  final int refresh;

  const PostListKey(this.postList, this.refresh);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PostListKey &&
          postList == other.postList &&
          refresh == other.refresh);

  @override
  int get hashCode => Object.hash(postList, refresh);
}
