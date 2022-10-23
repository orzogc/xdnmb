import 'dart:io';

import 'package:http/http.dart';
import 'package:http/io_client.dart';

class XdnmbHttpClient extends IOClient {
  static const Duration _timeout = Duration(seconds: 15);

  static const Duration __timeout = Duration(seconds: 16);

  static const Duration _idleTimeout = Duration(seconds: 90);

  static const String _userAgent = 'xdnmb';

  static final XdnmbHttpClient _client = XdnmbHttpClient._internal();

  factory XdnmbHttpClient() => _client;

  XdnmbHttpClient._internal()
      : super(HttpClient()
          ..connectionTimeout = _timeout
          ..idleTimeout = _idleTimeout);

  @override
  Future<IOStreamedResponse> send(BaseRequest request) {
    // 添加User-Agent
    request.headers[HttpHeaders.userAgentHeader] = _userAgent;

    // 确保超时时间
    return super.send(request).timeout(__timeout);
  }
}
