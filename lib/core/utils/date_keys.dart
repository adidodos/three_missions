/// Date key utilities for Firestore document IDs and week grouping.
///
/// - dateKey: "YYYY-MM-DD" format string
/// - weekKey: Monday-based week identifier (해당 주 월요일의 dateKey)
library;

import 'package:intl/intl.dart';

/// Date key format: "YYYY-MM-DD"
final _dateFormat = DateFormat('yyyy-MM-dd');

/// Converts [DateTime] to dateKey string ("YYYY-MM-DD").
///
/// Example:
/// ```dart
/// toDateKey(DateTime(2024, 1, 15)) // "2024-01-15"
/// ```
String toDateKey(DateTime date) {
  return _dateFormat.format(date);
}

/// Parses dateKey string to [DateTime].
///
/// Example:
/// ```dart
/// fromDateKey("2024-01-15") // DateTime(2024, 1, 15)
/// ```
DateTime fromDateKey(String dateKey) {
  return _dateFormat.parseStrict(dateKey);
}

/// Returns the weekKey for a given [date].
///
/// weekKey is the dateKey of the Monday of that week.
/// Week starts on Monday (ISO 8601 standard).
///
/// Example:
/// ```dart
/// // Wednesday 2024-01-17 -> Monday 2024-01-15
/// toWeekKey(DateTime(2024, 1, 17)) // "2024-01-15"
///
/// // Sunday 2024-01-21 -> Monday 2024-01-15
/// toWeekKey(DateTime(2024, 1, 21)) // "2024-01-15"
///
/// // Monday 2024-01-15 -> Monday 2024-01-15
/// toWeekKey(DateTime(2024, 1, 15)) // "2024-01-15"
/// ```
String toWeekKey(DateTime date) {
  final monday = toMondayOfWeek(date);
  return toDateKey(monday);
}

/// Returns the Monday of the week containing [date].
///
/// Uses ISO 8601 week definition (Monday = 1, Sunday = 7).
DateTime toMondayOfWeek(DateTime date) {
  // DateTime.weekday: Monday = 1, Sunday = 7
  final daysFromMonday = date.weekday - DateTime.monday; // 0 for Monday, 6 for Sunday
  return DateTime(date.year, date.month, date.day - daysFromMonday);
}

/// Returns the Sunday of the week containing [date].
DateTime toSundayOfWeek(DateTime date) {
  final monday = toMondayOfWeek(date);
  return monday.add(const Duration(days: 6));
}

/// Generates a workout document ID.
///
/// Format: "{uid}_{dateKey}"
/// This ensures one workout per user per day.
///
/// Example:
/// ```dart
/// toWorkoutId("user123", DateTime(2024, 1, 15)) // "user123_2024-01-15"
/// ```
String toWorkoutId(String uid, DateTime date) {
  return '${uid}_${toDateKey(date)}';
}

/// Parses workout ID to extract uid and dateKey.
///
/// Returns null if format is invalid.
({String uid, String dateKey})? parseWorkoutId(String workoutId) {
  final parts = workoutId.split('_');
  if (parts.length < 2) return null;

  final dateKey = parts.last;
  final uid = parts.sublist(0, parts.length - 1).join('_');

  // Validate dateKey format
  try {
    fromDateKey(dateKey);
    return (uid: uid, dateKey: dateKey);
  } catch (_) {
    return null;
  }
}

/// Returns today's date with time set to midnight.
DateTime today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

/// Returns today's dateKey.
String todayKey() {
  return toDateKey(today());
}

/// Returns this week's weekKey (Monday of current week).
String thisWeekKey() {
  return toWeekKey(today());
}
