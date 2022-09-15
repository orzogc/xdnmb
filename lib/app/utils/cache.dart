import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/io_client.dart';

class XdnmbImageCacheManager extends CacheManager with ImageCacheManager {
  static const String _key = 'xdnmbImageCache';

  static const Duration _timeout = Duration(seconds: 15);

  static const Duration _idleTimeout = Duration(seconds: 90);

  static final XdnmbImageCacheManager _manager =
      XdnmbImageCacheManager._internal();

  factory XdnmbImageCacheManager() => _manager;

  XdnmbImageCacheManager._internal()
      : super(
          Config(
            _key,
            fileService: HttpFileService(
              httpClient: IOClient(
                HttpClient()
                  ..connectionTimeout = _timeout
                  ..idleTimeout = _idleTimeout,
              ),
            ),
          ),
        );
}
