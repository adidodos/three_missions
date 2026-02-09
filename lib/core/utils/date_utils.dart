import 'package:intl/intl.dart';

class AppDateUtils {
  static final _dateFormat = DateFormat('yyyy-MM-dd');
  static final _displayFormat = DateFormat('M월 d일 (E)', 'ko');
  static final _monthFormat = DateFormat('yyyy년 M월', 'ko');

  static String toDateString(DateTime date) {
    return _dateFormat.format(date);
  }

  static DateTime fromDateString(String dateStr) {
    return _dateFormat.parse(dateStr);
  }

  static String toDisplayString(DateTime date) {
    return _displayFormat.format(date);
  }

  static String toMonthString(DateTime date) {
    return _monthFormat.format(date);
  }

  static DateTime today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static DateTime startOfWeek(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  static DateTime endOfWeek(DateTime date) {
    final weekday = date.weekday;
    return date.add(Duration(days: 7 - weekday));
  }

  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  static DateTime endOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  static List<DateTime> getDatesInRange(DateTime start, DateTime end) {
    final dates = <DateTime>[];
    var current = start;
    while (!current.isAfter(end)) {
      dates.add(current);
      current = current.add(const Duration(days: 1));
    }
    return dates;
  }
}
