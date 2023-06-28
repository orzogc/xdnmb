import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:http/io_client.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

import '../data/services/settings.dart';
import '../data/services/xdnmb_client.dart';

class XdnmbHttpClient extends IOClient {
  static const Duration idleTimeout = Duration(seconds: 90);

  static const String _userAgent = 'xdnmb';

  static final HttpClient httpClient = HttpClient()
    ..connectionTimeout = SettingsService.connectionTimeoutSecond
    ..idleTimeout = idleTimeout
    ..findProxy = HttpClient.findProxyFromEnvironment
    ..userAgent = _userAgent
    ..connectionFactory = (url, proxyHost, proxyPort) {
      late final Future<ConnectionTask<Socket>> connection;
      if (url.isScheme('https') && proxyHost == null && proxyPort == null) {
        final host = (XdnmbClientService.to.hasUpdateUrls &&
                SettingsService.to.useBackupApi &&
                XdnmbUrls().useBackupApi &&
                XdnmbUrls().isBaseUrl(url))
            ? XdnmbUrls().backupApiUrl.host
            : url.host;

        connection =
            SecureSocket.startConnect(host, HttpClient.defaultHttpsPort);
      } else {
        if (proxyHost != null && proxyPort != null) {
          connection = Socket.startConnect(proxyHost, proxyPort);
        } else {
          connection =
              Socket.startConnect(url.host, HttpClient.defaultHttpPort);
        }
      }

      connection.then(
        (task) => task.socket.timeout(SettingsService.connectionTimeoutSecond,
            onTimeout: () {
          task.cancel();

          throw const SocketException('Connection timed out');
        }),
      );

      return connection;
    };

  static final XdnmbHttpClient _client = XdnmbHttpClient._internal();

  factory XdnmbHttpClient() => _client;

  XdnmbHttpClient._internal() : super(httpClient);

  @override
  Future<IOStreamedResponse> send(BaseRequest request) {
    debugPrint('send an HTTP request, url: ${request.url}');

    return super.send(request);
  }
}
