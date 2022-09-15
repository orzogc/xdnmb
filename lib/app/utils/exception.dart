import 'package:xdnmb_api/xdnmb_api.dart';

String exceptionMessage(Object e) {
  late final String message;
  if (e is XdnmbApiException) {
    message = e.message;
  } else {
    message = e.toString();
  }

  return message;
}
