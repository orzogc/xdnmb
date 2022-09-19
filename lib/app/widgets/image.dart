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

  final _tag = UniqueKey();

  ThumbImage({super.key, required this.post, this.poUserHash});

  @override
  Widget build(BuildContext context) {
    final thumbImage = post.thumbImageUrl();
    final image = post.imageUrl();

    return (thumbImage != null)
        ? GestureDetector(
            onTap: () {
              if (image != null) {
                AppRoutes.toImage(ImageController(
                    tag: _tag, post: post, poUserHash: poUserHash));
              }
            },
            child: Hero(
              tag: _tag,
              child: CachedNetworkImage(
                imageUrl: thumbImage,
                fit: BoxFit.contain,
                cacheManager: XdnmbImageCacheManager(),
                progressIndicatorBuilder: loadingThumbImageIndicatorBuilder,
                errorWidget: loadingImageErrorBuilder,
              ),
            ),
          )
        : const SizedBox.shrink();
  }
}
