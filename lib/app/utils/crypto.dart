import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';

const String _chars =
    'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';

String randomString(int length) {
  late final Random random;
  try {
    random = Random.secure();
  } catch (e) {
    debugPrint('初始化安全随机数生成器失败：$e');
    random = Random(DateTime.now().microsecondsSinceEpoch);
  }

  return String.fromCharCodes(Iterable.generate(
      length, (index) => _chars.codeUnitAt(random.nextInt(_chars.length))));
}

String sha512256Hash(String text, {String? salt}) {
  if (salt != null) {
    text = salt + text;
  }

  return sha512256.convert(utf8.encode(text)).toString();
}
