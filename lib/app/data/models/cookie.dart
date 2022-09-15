import 'package:hive/hive.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

part 'cookie.g.dart';

@HiveType(typeId: 2)
class CookieData extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String userHash;

  @HiveField(2, defaultValue: null)
  final int? id;

  @HiveField(3, defaultValue: false)
  final bool isDeprecated;

  @HiveField(4, defaultValue: null)
  String? note;

  CookieData(
      {required this.name,
      required this.userHash,
      this.id,
      this.isDeprecated = false,
      this.note});

  CookieData.fromXdnmbCookie(
      {required XdnmbCookie cookie, this.isDeprecated = false, this.note})
      : name = cookie.name!,
        userHash = cookie.userHash,
        id = cookie.id;

  CookieData deprecate() => CookieData(
      name: name, userHash: userHash, id: id, isDeprecated: true, note: note);

  Future<void> editNote(String? note) async {
    this.note = note;
    await save();
  }

  CookieData copy() => CookieData(
      name: name,
      userHash: userHash,
      id: id,
      isDeprecated: isDeprecated,
      note: note);

  String cookie() => 'userhash=$userHash';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CookieData &&
          name == other.name &&
          userHash == other.userHash &&
          id == other.id &&
          isDeprecated == other.isDeprecated &&
          note == other.note);

  @override
  int get hashCode => Object.hash(name, userHash, id, isDeprecated, note);
}
