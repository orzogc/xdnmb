import 'package:flutter/material.dart';
import 'package:xdnmb/app/widgets/dialog.dart';

import '../routes/routes.dart';
import '../utils/extensions.dart';
import '../utils/launch.dart';
import '../widgets/reference.dart';

Future<void> parseUrl({required String url, String? poUserHash}) async {
  final parsed = Uri.tryParse(url);

  if (parsed != null) {
    if (parsed.host.isEmpty) {
      if (parsed.pathSegments.isNotEmpty) {
        switch (parsed.pathSegments[0]) {
          case PathNames.reference:
            final id = parsed.queryParameters['postId'].tryParseInt();
            if (id != null) {
              postListDialog(Center(
                  child: ReferenceCard(postId: id, poUserHash: poUserHash)));
            } else {
              debugPrint('未知的引用链接：$url');
            }
            break;
          default:
            debugPrint('未知的链接：$url');
        }
      }
    } else {
      await launchUri(parsed);
    }
  }
}
