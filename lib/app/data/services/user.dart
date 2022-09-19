import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

import '../models/cookie.dart';
import '../models/hive.dart';
import '../models/user.dart';
import '../services/xdnmb_client.dart';

class UserService extends GetxService {
  static const String _secureKey = 'xdnmbUserData';

  static UserService get to => Get.find<UserService>();

  late final Box _userBox;

  late final Box<CookieData> _cookiesBox;

  final RxBool isReady = false.obs;

  bool canGetCookie = false;

  int currentCookiesNum = 0;

  int totalCookiesNum = 0;

  String? get userCookie => _userBox.get(User.userCookie);

  set userCookie(String? userCookie) =>
      _userBox.put(User.userCookie, userCookie);

  DateTime? get userCookieExpireDate => _userBox.get(User.userCookieExpireDate);

  set userCookieExpireDate(DateTime? dateTime) =>
      _userBox.put(User.userCookieExpireDate, dateTime);

  CookieData? get browseCookie => _userBox.get(User.browseCookie);

  set browseCookie(CookieData? browseCookie) =>
      _userBox.put(User.browseCookie, browseCookie);

  CookieData? get postCookie => _userBox.get(User.postCookie);

  set postCookie(CookieData? postCookie) =>
      _userBox.put(User.postCookie, postCookie);

  bool get isLogin => userCookie != null;

  bool? get isUserCookieExpired => userCookieExpireDate != null
      ? DateTime.now().compareTo(userCookieExpireDate!) >= 0
      : null;

  bool get isUserCookieValid => isLogin && !(isUserCookieExpired ?? true);

  bool get hasBrowseCookie => browseCookie != null;

  bool get hasPostCookie => postCookie != null;

  Iterable<CookieData> get xdnmbCookies => _cookiesBox.values;

  bool get hasXdnmbCookie => xdnmbCookies.isNotEmpty;

  late final ValueListenable<Box> userCookieListenable;

  late final ValueListenable<Box> browseCookieListenable;

  late final ValueListenable<Box> postCookieListenable;

  late final ValueListenable<Box<CookieData>> cookiesListenable;

  void updateClient() {
    final client = XdnmbClientService.to.client;

    if (isLogin) {
      client.xdnmbUserCookie = Cookie.fromSetCookieValue(userCookie!);
    }
    if (hasBrowseCookie) {
      client.xdnmbCookie = XdnmbCookie(browseCookie!.userHash,
          name: browseCookie!.name, id: browseCookie?.id);
    }
  }

  Future<void> login(
      {required String email,
      required String password,
      required String verify}) async {
    final client = XdnmbClientService.to.client;
    if (client.isLogin) {
      debugPrint('XdnmbClient已经登陆过了');
    }

    await client.userLogin(email: email, password: password, verify: verify);
    if (client.isLogin) {
      userCookie = client.xdnmbUserCookie!.toString();
      userCookieExpireDate = client.xdnmbUserCookie!.expires;
    }
  }

  void logout() {
    userCookie = null;
    userCookieExpireDate = null;
  }

  Future<void> updateCookies() async {
    final client = XdnmbClientService.to.client;
    if (!isUserCookieValid) {
      debugPrint('没有登陆或者登陆过期无法获取饼干');
      return;
    }
    if (isLogin && !client.isLogin) {
      debugPrint('XdnmbClient没有设置userCookie');
      updateClient();
    }

    final list = await client.getCookiesList();
    canGetCookie = list.canGetCookie;
    currentCookiesNum = list.currentCookiesNum;
    totalCookiesNum = list.totalCookiesNum;

    final normal = <CookieData>[];
    for (final cookieId in list.cookiesIdList) {
      if (!xdnmbCookies.any((cookie) {
        if (cookie.id == cookieId) {
          normal.add(cookie);
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
      if (!list.cookiesIdList.any((cookieId) => cookieId == cookie.id)) {
        deprecated.add(cookie.deprecate());
      }
    }

    await _cookiesBox.clear();
    await _cookiesBox.addAll(normal.followedBy(deprecated));
  }

  /// 返回`true`说明添加成功，返回`false`说明已存在该饼干
  Future<bool> addCookie(
      {required String name, required String userHash, String? note}) async {
    if (xdnmbCookies.any((cookie) => cookie.userHash == userHash)) {
      return false;
    }

    await _cookiesBox
        .add(CookieData(name: name, userHash: userHash, note: note));
    return true;
  }

  Future<void> addNewCookie(String verify) async {
    await XdnmbClientService.to.client.getNewCookie(verify: verify);
    await updateCookies();
  }

  void updateBrowseCookie() {
    if (hasXdnmbCookie) {
      if (!xdnmbCookies
          .any((cookie) => cookie.userHash == browseCookie?.userHash)) {
        browseCookie = _cookiesBox.getAt(0)!.copy();
      }
    } else {
      browseCookie = null;
    }
  }

  void updatePostCookie() {
    if (hasXdnmbCookie) {
      if (!xdnmbCookies
          .any((cookie) => cookie.userHash == postCookie?.userHash)) {
        postCookie = _cookiesBox.getAt(0)!.copy();
      }
    } else {
      postCookie = null;
    }
  }

  @override
  void onInit() async {
    super.onInit();

    const storage = FlutterSecureStorage();
    late final List<int> key;
    if (await storage.containsKey(key: _secureKey)) {
      key = base64.decode((await storage.read(key: _secureKey))!);
    } else {
      key = Hive.generateSecureKey();
      await storage.write(key: _secureKey, value: base64.encode(key));
    }

    _userBox = await Hive.openBox(HiveBoxName.user,
        encryptionCipher: HiveAesCipher(key));
    _cookiesBox = await Hive.openBox<CookieData>(HiveBoxName.cookies,
        encryptionCipher: HiveAesCipher(key));

    updateClient();

    _userBox.watch(key: User.userCookie).listen((event) {
      final cookie = event.value as String?;
      final client = XdnmbClientService.to.client;
      if (cookie != null) {
        client.xdnmbUserCookie = Cookie.fromSetCookieValue(cookie);
      } else {
        client.xdnmbUserCookie = null;
      }
    });

    _userBox.watch(key: User.browseCookie).listen((event) {
      final cookie = event.value as CookieData?;
      final client = XdnmbClientService.to.client;
      if (cookie != null) {
        client.xdnmbCookie =
            XdnmbCookie(cookie.userHash, name: cookie.name, id: cookie.id);
      } else {
        client.xdnmbCookie = null;
      }
    });

    updateBrowseCookie();
    updatePostCookie();
    _cookiesBox.watch().listen((event) {
      updateBrowseCookie();
      updatePostCookie();
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
    await _userBox.close();
    await _cookiesBox.close();
    isReady.value = false;

    super.onClose();
  }
}
