import 'dart:io';

import 'package:http/http.dart';
import 'package:http/io_client.dart';

/* class _Address implements InternetAddress {
  @override
  final String address;

  @override
  final String host;

  final Uint8List _rawAddress;

  @override
  bool get isLinkLocal => false;

  @override
  bool get isLoopback => false;

  @override
  bool get isMulticast => false;

  @override
  Uint8List get rawAddress => Uint8List.fromList(_rawAddress);

  @override
  Future<InternetAddress> reverse() {
    throw UnimplementedError();
  }

  @override
  InternetAddressType get type => InternetAddressType.IPv4;

  _Address({required this.address, required this.host})
      : _rawAddress = Uint8List.fromList(
            address.split('.').map((n) => int.parse(n)).toList());
} */

class XdnmbHttpClient extends IOClient {
  static const Duration connectionTimeout = Duration(seconds: 15);

  static final Duration _timeout =
      connectionTimeout + const Duration(seconds: 1);

  static const Duration idleTimeout = Duration(seconds: 90);

  static const String _userAgent = 'xdnmb';

  static final HttpClient httpClient = HttpClient()
    ..connectionTimeout = connectionTimeout
    ..idleTimeout = idleTimeout
    ..findProxy = HttpClient.findProxyFromEnvironment;

  static final XdnmbHttpClient _client = XdnmbHttpClient._internal();

  factory XdnmbHttpClient() => _client;

  XdnmbHttpClient._internal() : super(httpClient);

  @override
  Future<IOStreamedResponse> send(BaseRequest request) {
    // 添加User-Agent
    request.headers[HttpHeaders.userAgentHeader] = _userAgent;

    // 确保超时时间
    return super.send(request).timeout(_timeout);
  }
}

/* ..connectionFactory = (url, proxyHost, proxyPort) {
            InternetAddress? address;
            if (url.host == 'image.nmb.best') {
              address = _cdn;
            }

            if (url.isScheme('https') &&
                proxyHost == null &&
                proxyPort == null) {
              return SecureSocket.startConnect(
                  address ?? url.host, HttpClient.defaultHttpsPort,
                  context: SecurityContext.defaultContext);
              /* return Socket.startConnect(
                  address ?? url.host, HttpClient.defaultHttpPort); */
            } else if (url.isScheme('http')) {
              if (proxyHost != null && proxyPort != null) {
                return Socket.startConnect(proxyHost, proxyPort);
              } else {
                return Socket.startConnect(
                    address ?? url.host, HttpClient.defaultHttpPort);
              }
            } else {
              throw UnsupportedError('未知URI和proxy：$url $proxyHost $proxyPort');
            }
          } */
