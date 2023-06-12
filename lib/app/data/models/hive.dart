import 'dart:io';

import 'package:path/path.dart';

import '../../utils/directory.dart';
import '../../utils/extensions.dart';

abstract class HiveBoxName {
  static const String forums = 'forums';

  static const String settings = 'settings';

  static const String user = 'user';

  static const String cookies = 'cookies';

  static const String deletedCookies = 'deletedCookies';

  static const String data = 'data';

  static const String draft = 'draft';

  static const String emoticon = 'emoticon';

  static const String forumBlacklist = 'forumBlacklist';

  static const String postBlacklist = 'postBlacklist';

  static const String userBlacklist = 'userBlacklist';

  static const String controllers = 'controllers';

  static const String tags = 'tags';
}

String _hiveFilename(String name) => '${name.toLowerCase()}.hive';

String _hiveLockFilename(String name) => '${name.toLowerCase()}.lock';

String _hiveFilePathInDir(String dir, String name) =>
    join(dir, _hiveFilename(name));

File _hiveBackupLockFile(String name) =>
    File(join(databaseDirectory, _hiveLockFilename(hiveBackupName(name))));

String hiveBackupName(String name) => '${name.toLowerCase()}_backup';

String hiveBackupFilePath(String name) =>
    hiveBackupFilePathInDir(databaseDirectory, name);

String hiveBackupFilePathInDir(String dir, String name) =>
    join(dir, _hiveFilename(hiveBackupName(name)));

File hiveFile(String name) => File(_hiveFilePathInDir(databaseDirectory, name));

File hiveBackupFile(String name) =>
    hiveBackupFileInDir(databaseDirectory, name);

File hiveBackupFileInDir(String dir, String name) =>
    File(hiveBackupFilePathInDir(dir, name));

Future<void> deleteHiveBackupFile(String name) =>
    hiveBackupFile(name).deleteIfExist();

Future<void> deleteHiveBackupLockFile(String name) =>
    _hiveBackupLockFile(name).deleteIfExist();

Future<File> copyHiveFileToBackupDir(String dir, String name) =>
    hiveFile(name).copy(hiveBackupFilePathInDir(dir, name));

Future<File> copyHiveBackupFile(String dir, String name) async {
  await deleteHiveBackupFile(name);
  await deleteHiveBackupLockFile(name);

  return hiveBackupFileInDir(dir, name).copy(hiveBackupFilePath(name));
}
