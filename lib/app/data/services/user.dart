import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

import '../../widgets/listenable.dart';
import '../models/cookie.dart';
import '../models/hive.dart';
import '../models/user.dart';
import '../services/xdnmb_client.dart';

class UserService extends GetxService {
  static const String _secureKey = 'xdnmbUserData';

  static UserService get to => Get.find<UserService>();

  late final Box _userBox;

  late final Box<CookieData> _cookiesBox;

  late final Box<CookieData> _deletedCookiesBox;

  final RxBool isReady = false.obs;

  bool canGetCookie = false;

  final RxInt currentCookiesNum = 0.obs;

  final RxInt totalCookiesNum = 0.obs;

  late HashMap<String, int> _cookieColorMap;

  final Notifier cookieColorNotifier = Notifier();

  /// 用户帐号cookie
  String? get userCookie => _userBox.get(User.userCookie);

  set userCookie(String? userCookie) =>
      _userBox.put(User.userCookie, userCookie);

  /// 用户帐号cookie的过期日期
  DateTime? get userCookieExpireDate => _userBox.get(User.userCookieExpireDate);

  set userCookieExpireDate(DateTime? dateTime) =>
      _userBox.put(User.userCookieExpireDate, dateTime);

  /// 浏览用的饼干
  CookieData? get browseCookie => _userBox.get(User.browseCookie);

  set browseCookie(CookieData? browseCookie) =>
      _userBox.put(User.browseCookie, browseCookie);

  /// 发串用的饼干
  CookieData? get postCookie => _userBox.get(User.postCookie);

  set postCookie(CookieData? postCookie) =>
      _userBox.put(User.postCookie, postCookie);

  bool get isLogin => userCookie != null;

  bool? get isUserCookieExpired => userCookieExpireDate != null
      ? DateTime.now().isAfter(userCookieExpireDate!)
      : null;

  bool get isUserCookieValid => isLogin && !(isUserCookieExpired ?? true);

  bool get hasBrowseCookie => browseCookie != null;

  bool get hasPostCookie => postCookie != null;

  Iterable<CookieData> get xdnmbCookies => _cookiesBox.values;

  bool get hasXdnmbCookie => _cookiesBox.isNotEmpty;

  late final ValueListenable<Box> userCookieListenable;

  late final ValueListenable<Box> browseCookieListenable;

  late final ValueListenable<Box> postCookieListenable;

  late final ValueListenable<Box<CookieData>> cookiesListenable;

  late final StreamSubscription<BoxEvent> _userCookieSubscription;

  late final StreamSubscription<BoxEvent> _browseCookieSubscription;

  late final StreamSubscription<BoxEvent> _cookiesBoxSubscription;

  void _updateClient() {
    final client = XdnmbClientService.to.client;

    if (isLogin) {
      client.xdnmbUserCookie = Cookie.fromSetCookieValue(userCookie!);
    }
    if (hasBrowseCookie) {
      client.xdnmbCookie = XdnmbCookie(browseCookie!.userHash,
          name: browseCookie!.name, id: browseCookie?.id);
    }
  }

  void _updateBrowseCookie() {
    if (hasXdnmbCookie) {
      if (!xdnmbCookies
          .any((cookie) => cookie.userHash == browseCookie?.userHash)) {
        browseCookie = _cookiesBox.getAt(0)!.copy();
      }
    } else {
      browseCookie = null;
    }
  }

  void _updatePostCookie() {
    if (hasXdnmbCookie) {
      if (!xdnmbCookies
          .any((cookie) => cookie.userHash == postCookie?.userHash)) {
        postCookie = _cookiesBox.getAt(0)!.copy();
      }
    } else {
      postCookie = null;
    }
  }

  void _updateCookieColorMap() {
    _cookieColorMap = HashMap.fromEntries(_deletedCookiesBox.values
        .followedBy(xdnmbCookies)
        .map((cookie) => MapEntry(cookie.name, cookie.colorValue)));

    cookieColorNotifier.notify();
  }

  void _setCookieColorInMap(String name, int color) {
    _cookieColorMap[name] = color;

    cookieColorNotifier.notify();
  }

  Future<void> login(
      {required String email,
      required String password,
      required String verify}) async {
    final client = XdnmbClientService.to.client;
    if (client.isLogin) {
      debugPrint('XdnmbClient已经登陆过了');
    }

    try {
      await client.userLogin(email: email, password: password, verify: verify);
      if (client.isLogin) {
        userCookie = client.xdnmbUserCookie!.toString();
        userCookieExpireDate = client.xdnmbUserCookie!.expires;
      }
    } catch (e) {
      logout();
      rethrow;
    }
  }

  void logout() {
    userCookie = null;
    userCookieExpireDate = null;
  }

  Future<void> updateCookies() async {
    debugPrint('开始更新饼干');

    final client = XdnmbClientService.to.client;
    if (!isUserCookieValid) {
      debugPrint('没有登陆或者登陆过期无法获取饼干');
      return;
    }
    if (isLogin && !client.isLogin) {
      debugPrint('XdnmbClient没有设置userCookie');
      _updateClient();
    }

    final list = await client.getCookiesList();
    canGetCookie = list.canGetCookie;
    currentCookiesNum.value = list.currentCookiesNum;
    totalCookiesNum.value = list.totalCookiesNum;

    final normal = <CookieData>[];
    for (final cookieId in list.cookiesIdList) {
      if (!xdnmbCookies.any((cookie) {
        if (cookie.id == cookieId) {
          normal.add(cookie.copy());
          return true;
        }
        return false;
      })) {
        normal.add(CookieData.fromXdnmbCookie(
            cookie: await client.getCookie(cookieId)));
      }
    }

    final deprecated = <CookieData>[];
    for (final cookie in xdnmbCookies) {
      if (normal.any((cookie_) => cookie_.userHash == cookie.userHash)) {
        if (cookie.id == null) {
          final cookie_ = normal
              .firstWhere((cookie_) => cookie_.userHash == cookie.userHash);
          cookie_.note = cookie.note;
          cookie_.lastPostTime = cookie.lastPostTime;
          cookie_.colorValue = cookie.colorValue;
        }
      } else {
        deprecated.add(cookie.deprecate());
      }
    }

    await _cookiesBox.clear();
    await _cookiesBox.addAll(normal.followedBy(deprecated));

    _updateCookieColorMap();
  }

  /// 返回`true`说明添加成功，返回`false`说明已存在该饼干
  Future<bool> addCookie(
      {required String name, required String userHash, String? note}) async {
    if (xdnmbCookies
        .any((cookie) => cookie.name == name || cookie.userHash == userHash)) {
      return false;
    }

    await _cookiesBox
        .add(CookieData(name: name, userHash: userHash, note: note));
    _setCookieColorInMap(name, CookieData.defaultColor);

    return true;
  }

  Future<void> addNewCookie(String verify) async {
    await XdnmbClientService.to.client.getNewCookie(verify: verify);
    await updateCookies();
  }

  Future<void> deleteCookie(CookieData cookie) async {
    await cookie.delete();
    await _deletedCookiesBox.put(cookie.name, cookie.deleted());
  }

  Future<void> updateLastPostTime() async {
    for (final cookie in xdnmbCookies) {
      if (cookie.userHash == postCookie?.userHash) {
        await cookie.setLastPostTime(DateTime.now());
      }
    }
  }

  Color? getCookieColor(String name) {
    final color = _cookieColorMap[name];

    return color != null ? Color(color) : null;
  }

  Future<void> setCookieColor(CookieData cookie, Color color) async {
    await cookie.setColor(color);
    _setCookieColorInMap(cookie.name, color.value);
  }

  @override
  void onInit() async {
    super.onInit();

    const storage = FlutterSecureStorage();
    late final List<int> key;
    if (await storage.containsKey(key: _secureKey)) {
      final storageKey = await storage.read(key: _secureKey);
      if (storageKey != null) {
        key = base64.decode(storageKey);
      } else {
        key = Hive.generateSecureKey();
        await storage.write(key: _secureKey, value: base64.encode(key));
      }
    } else {
      key = Hive.generateSecureKey();
      await storage.write(key: _secureKey, value: base64.encode(key));
    }

    _userBox = await Hive.openBox(HiveBoxName.user,
        encryptionCipher: HiveAesCipher(key));
    _cookiesBox = await Hive.openBox<CookieData>(HiveBoxName.cookies,
        encryptionCipher: HiveAesCipher(key));
    _deletedCookiesBox = await Hive.openBox<CookieData>(
        HiveBoxName.deletedCookies,
        encryptionCipher: HiveAesCipher(key));

    _updateClient();
    _updateCookieColorMap();

    _userCookieSubscription =
        _userBox.watch(key: User.userCookie).listen((event) {
      debugPrint('userCookie change');
      final cookie = event.value as String?;
      final client = XdnmbClientService.to.client;
      if (cookie != null) {
        client.xdnmbUserCookie = Cookie.fromSetCookieValue(cookie);
      } else {
        client.xdnmbUserCookie = null;
      }
    });

    _browseCookieSubscription =
        _userBox.watch(key: User.browseCookie).listen((event) {
      debugPrint('browseCookie change');
      final cookie = event.value as CookieData?;
      final client = XdnmbClientService.to.client;
      if (cookie != null) {
        client.xdnmbCookie =
            XdnmbCookie(cookie.userHash, name: cookie.name, id: cookie.id);
      } else {
        client.xdnmbCookie = null;
      }
    });

    _updateBrowseCookie();
    _updatePostCookie();
    _cookiesBoxSubscription = _cookiesBox.watch().listen((event) {
      debugPrint('_cookiesBox change');
      _updateBrowseCookie();
      _updatePostCookie();
    });

    userCookieListenable = _userBox.listenable(keys: [User.userCookie]);
    browseCookieListenable = _userBox.listenable(keys: [User.browseCookie]);
    postCookieListenable = _userBox.listenable(keys: [User.postCookie]);
    cookiesListenable = _cookiesBox.listenable();

    isReady.value = true;
    debugPrint('读取用户数据成功');
  }

  @override
  void onClose() async {
    await _userCookieSubscription.cancel();
    await _browseCookieSubscription.cancel();
    await _cookiesBoxSubscription.cancel();
    await _userBox.close();
    await _cookiesBox.close();
    isReady.value = false;

    super.onClose();
  }
}
