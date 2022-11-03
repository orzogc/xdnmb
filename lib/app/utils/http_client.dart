import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:http/io_client.dart';

class XdnmbHttpClient extends IOClient {
  static const Duration connectionTimeout = Duration(seconds: 15);

  static const Duration idleTimeout = Duration(seconds: 90);

  static const String _userAgent = 'xdnmb';

  static final HttpClient httpClient = HttpClient()
    ..connectionTimeout = connectionTimeout
    ..idleTimeout = idleTimeout
    ..findProxy = HttpClient.findProxyFromEnvironment
    ..connectionFactory = (url, proxyHost, proxyPort) {
      late final Future<ConnectionTask<Socket>> connection;
      if (url.isScheme('https') && proxyHost == null && proxyPort == null) {
        connection =
            SecureSocket.startConnect(url.host, HttpClient.defaultHttpsPort);
      } else {
        if (proxyHost != null && proxyPort != null) {
          connection = Socket.startConnect(proxyHost, proxyPort);
        } else {
          connection =
              Socket.startConnect(url.host, HttpClient.defaultHttpPort);
        }
      }

      connection.then((task) {
        final socket = task.socket;

        socket.timeout(connectionTimeout, onTimeout: () {
          task.cancel();

          throw const SocketException('Connection timed out');
        });
      });

      return connection;
    };

  static final XdnmbHttpClient _client = XdnmbHttpClient._internal();

  factory XdnmbHttpClient() => _client;

  XdnmbHttpClient._internal() : super(httpClient);

  @override
  Future<IOStreamedResponse> send(BaseRequest request) {
    debugPrint('send an HTTP request, url: ${request.url}');

    // 添加User-Agent
    request.headers[HttpHeaders.userAgentHeader] = _userAgent;

    return super.send(request);
  }
}
