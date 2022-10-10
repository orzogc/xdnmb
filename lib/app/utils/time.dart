import 'package:date_format/date_format.dart';

import '../data/services/time.dart';

const List<String> _fullFormat = [yy, '/', m, '/', d, ' ', H, ':', nn, ':', ss];

const List<String> _sameYearFormat = [m, '/', d, ' ', H, ':', nn, ':', ss];

const List<String> _sameDayFormat = [H, ':', nn, ':', ss];

const List<String> _imageFilenameFormat = [yyyy, mm, dd, HH, nn, ss];

const List<String> _dateRangeFormat = [yyyy, '/', mm, '/', dd];

String postFormatTime(DateTime time) {
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

String imageFilenameTime() => formatDate(DateTime.now(), _imageFilenameFormat);

String dateRangeFormatTime(DateTime time) => formatDate(time, _dateRangeFormat);
