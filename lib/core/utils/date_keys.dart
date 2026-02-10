/// Date key utilities for Firestore document IDs and week grouping.
///
/// - dateKey: "YYYY-MM-DD" format string
/// - weekKey: Monday-based week identifier (해당 주 월요일의 dateKey)
library;

import 'package:intl/intl.dart';

final _dateFormat = DateFormat('yyyy-MM-dd');

/// Converts [DateTime] to dateKey string ("YYYY-MM-DD").
String toDateKey(DateTime date) => _dateFormat.format(date);

/// Parses dateKey string to [DateTime].
DateTime fromDateKey(String dateKey) => _dateFormat.parseStrict(dateKey);

/// Returns the weekKey for a given [date].
/// weekKey is the dateKey of the Monday of that week (ISO 8601).
String toWeekKey(DateTime date) => toDateKey(toMondayOfWeek(date));

/// Returns the Monday of the week containing [date].
DateTime toMondayOfWeek(DateTime date) {
  final daysFromMonday = date.weekday - DateTime.monday;
  return DateTime(date.year, date.month, date.day - daysFromMonday);
}

/// Returns the Sunday of the week containing [date].
DateTime toSundayOfWeek(DateTime date) {
  return toMondayOfWeek(date).add(const Duration(days: 6));
}

/// Generates a workout document ID: "{uid}_{dateKey}"
/// This enforces one workout per user per day.
String toWorkoutId(String uid, DateTime date) => '${uid}_${toDateKey(date)}';

/// Parses workout ID to extract uid and dateKey.
({String uid, String dateKey})? parseWorkoutId(String workoutId) {
  final lastUnderscore = workoutId.lastIndexOf('_');
  if (lastUnderscore == -1) return null;

  final dateKey = workoutId.substring(lastUnderscore + 1);
  final uid = workoutId.substring(0, lastUnderscore);

  try {
    fromDateKey(dateKey);
    return (uid: uid, dateKey: dateKey);
  } catch (_) {
    return null;
  }
}

/// Returns today with time set to midnight.
DateTime today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

/// Returns today's dateKey.
String todayKey() => toDateKey(today());

/// Returns this week's weekKey (Monday).
String thisWeekKey() => toWeekKey(today());

/// Returns list of dates for the week containing [date].
List<DateTime> getWeekDates(DateTime date) {
  final monday = toMondayOfWeek(date);
  return List.generate(7, (i) => monday.add(Duration(days: i)));
}

/// Returns start and end of month.
(DateTime start, DateTime end) getMonthRange(DateTime date) {
  final start = DateTime(date.year, date.month, 1);
  final end = DateTime(date.year, date.month + 1, 0);
  return (start, end);
}
