import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../utils/directory.dart';
import '../../utils/toast.dart';

class ImageService extends GetxService {
  static ImageService get to => Get.find<ImageService>();

  String? savePath;

  final RxBool isReady = false.obs;

  @override
  void onReady() async {
    super.onReady();

    var isGranted = true;
    if (GetPlatform.isAndroid || GetPlatform.isIOS) {
      var status = await Permission.storage.status;
      if (status.isDenied) {
        status = await Permission.storage.request();
      }
      if (!status.isGranted) {
        isGranted = false;
        showToast('读取和保存图片需要存储权限');
      }
    }

    if (isGranted) {
      try {
        savePath = await picturesPath();
      } catch (e) {
        showToast('获取图片保存文件夹失败：$e');
      }
    }

    isReady.value = true;

    debugPrint('更新图片服务成功');
  }

  @override
  void onClose() {
    isReady.value = false;

    super.onClose();
  }
}

/* import 'package:double_linked_list/double_linked_list.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Node;
import 'package:xdnmb_api/xdnmb_api.dart';

class ImageListService extends GetxService {
  final DoubleLinkedList<PostBase> posts = DoubleLinkedList<PostBase>.empty();

  late Node<PostBase> current = posts.begin;

  //void init(PostBase post) => current = current.insertAfter(post);

  Node<PostBase> pushBack(PostBase post) => posts.last.insertAfter(post);

  Node<PostBase> pushFront(PostBase post) => posts.first.insertBefore(post);

  void pushBacks(Iterable<PostBase> posts) {
    var last = this.posts.last;
    for (final post in posts) {
      last = last.insertAfter(post);
    }
  }

  void pushFronts(Iterable<PostBase> posts) {
    var first = this.posts.first;
    for (final post in posts) {
      first = first.insertBefore(post);
    }
  }

  Node<PostBase>? updateCurrent(int postId) {
    try {
      current = posts.firstWhere((post) => post.id == postId);
      return current;
    } catch (e) {
      debugPrint('ImageListService里没找到postId为$postId的串');
      return null;
    }
  }

  Node<PostBase>? currentNext() {
    final next = current.next;
    if (next.isBegin || next.isEnd) {
      return null;
    }

    current = next;
    return current;
  }

  Node<PostBase>? currentPrevious() {
    final previous = current.previous;
    if (previous.isBegin || previous.isEnd) {
      return null;
    }

    current = previous;
    return current;
  }
}
*/
