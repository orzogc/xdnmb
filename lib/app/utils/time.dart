import 'package:date_format/date_format.dart';

import '../data/services/time.dart';

const List<String> _fullAllFormat = [
  yy,
  '/',
  m,
  '/',
  d,
  ' ',
  H,
  ':',
  nn,
  ':',
  ss
];

const List<String> _fullSameYearFormat = [m, '/', d, ' ', H, ':', nn, ':', ss];

const List<String> _fullSameDayFormat = [H, ':', nn, ':', ss];

const List<String> _allFormat = [yy, '/', m, '/', d, ' ', H, ':', nn];

const List<String> _sameYearFormat = [m, '/', d, ' ', H, ':', nn];

const List<String> _sameDayFormat = [H, ':', nn];

const List<String> _imageFilenameFormat = [yyyy, mm, dd, HH, nn, ss];

const List<String> _onlyDayFormat = [yyyy, '/', mm, '/', dd];

String fullFormatTime(DateTime time) {
  final now = TimeService.to.now;
  final localTime = time.toLocal();

  return formatDate(
      localTime,
      localTime.year != now.year
          ? _fullAllFormat
          : (localTime.month != now.month || localTime.day != now.day
              ? _fullSameYearFormat
              : _fullSameDayFormat));
}

String formatTime(DateTime time) {
  final now = TimeService.to.now;
  final localTime = time.toLocal();

  return formatDate(
      localTime,
      localTime.year != now.year
          ? _allFormat
          : (localTime.month != now.month || localTime.day != now.day
              ? _sameYearFormat
              : _sameDayFormat));
}

String imageFilenameTime() => formatDate(DateTime.now(), _imageFilenameFormat);

String formatDay(DateTime time) => formatDate(time, _onlyDayFormat);
