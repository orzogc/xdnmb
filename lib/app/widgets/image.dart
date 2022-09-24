import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xdnmb_api/xdnmb_api.dart' hide Image;

import '../modules/image.dart';
import '../routes/routes.dart';
import '../utils/cache.dart';
import 'loading.dart';

class ThumbImage extends StatelessWidget {
  final PostBase post;

  final String? poUserHash;

  final UniqueKey _tag = UniqueKey();

  final RxBool hasError = false.obs;

  ThumbImage({super.key, required this.post, this.poUserHash});

  @override
  Widget build(BuildContext context) => post.hasImage()
      ? GestureDetector(
          onTap: () {
            AppRoutes.toImage(
                ImageController(tag: _tag, post: post, poUserHash: poUserHash));
          },
          child: Hero(
            tag: _tag,
            // 部分GIF略缩图显示会出错
            child: Obx(
              () => CachedNetworkImage(
                imageUrl:
                    hasError.value ? post.imageUrl()! : post.thumbImageUrl()!,
                fit: BoxFit.contain,
                cacheManager: XdnmbImageCacheManager(),
                progressIndicatorBuilder: loadingThumbImageIndicatorBuilder,
                errorWidget: (context, url, error) {
                  if (!hasError.value) {
                    WidgetsBinding.instance.addPostFrameCallback(
                        (timeStamp) => hasError.value = true);
                  }

                  return hasError.value
                      ? loadingImageErrorBuilder(context, url, error)
                      : const SizedBox.shrink();
                },
              ),
            ),
          ),
        )
      : const SizedBox.shrink();
}
