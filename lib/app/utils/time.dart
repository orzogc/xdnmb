import 'package:date_format/date_format.dart';

import '../data/services/time.dart';

const List<String> _fullFormat = [yy, '/', m, '/', d, ' ', H, ':', nn];

const List<String> _sameYearFormat = [m, '/', d, ' ', H, ':', nn];

const List<String> _sameDayFormat = [H, ':', nn];

String formatTime(DateTime time) {
  final now = TimeService.to.now;
  final localTime = time.toLocal();

  return formatDate(
      localTime,
      localTime.year != now.year
          ? _fullFormat
          : (localTime.month != now.month || localTime.day != now.day
              ? _sameYearFormat
              : _sameDayFormat));
}
