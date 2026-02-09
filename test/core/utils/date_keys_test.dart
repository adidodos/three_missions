import 'package:flutter_test/flutter_test.dart';
import 'package:three_missions/core/utils/date_keys.dart';

void main() {
  group('dateKey', () {
    test('toDateKey formats date correctly', () {
      final date = DateTime(2024, 1, 15);
      expect(toDateKey(date), '2024-01-15');
    });

    test('fromDateKey parses dateKey correctly', () {
      final date = fromDateKey('2024-01-15');
      expect(date, DateTime(2024, 1, 15));
    });

    test('handles single digit month and day', () {
      expect(toDateKey(DateTime(2024, 1, 5)), '2024-01-05');
      expect(toDateKey(DateTime(2024, 9, 1)), '2024-09-01');
    });
  });

  group('weekKey', () {
    test('Monday returns same date as weekKey', () {
      // 2024-01-15 is Monday
      final monday = DateTime(2024, 1, 15);
      expect(monday.weekday, DateTime.monday);
      expect(toWeekKey(monday), '2024-01-15');
    });

    test('Sunday returns previous Monday as weekKey', () {
      // 2024-01-21 is Sunday
      final sunday = DateTime(2024, 1, 21);
      expect(sunday.weekday, DateTime.sunday);
      // Should return Monday 2024-01-15
      expect(toWeekKey(sunday), '2024-01-15');
    });

    test('Month boundary: Sunday at month end returns Monday from previous month', () {
      // 2024-03-03 is Sunday
      final sundayMarch = DateTime(2024, 3, 3);
      expect(sundayMarch.weekday, DateTime.sunday);
      // Monday of that week is 2024-02-26 (February)
      expect(toWeekKey(sundayMarch), '2024-02-26');
    });

    test('Wednesday returns Monday of same week', () {
      // 2024-01-17 is Wednesday
      final wednesday = DateTime(2024, 1, 17);
      expect(wednesday.weekday, DateTime.wednesday);
      expect(toWeekKey(wednesday), '2024-01-15');
    });

    test('Saturday returns Monday of same week', () {
      // 2024-01-20 is Saturday
      final saturday = DateTime(2024, 1, 20);
      expect(saturday.weekday, DateTime.saturday);
      expect(toWeekKey(saturday), '2024-01-15');
    });
  });

  group('toMondayOfWeek', () {
    test('returns correct Monday for each day of week', () {
      // Week of 2024-01-15 (Mon) to 2024-01-21 (Sun)
      final expectedMonday = DateTime(2024, 1, 15);

      expect(toMondayOfWeek(DateTime(2024, 1, 15)), expectedMonday); // Mon
      expect(toMondayOfWeek(DateTime(2024, 1, 16)), expectedMonday); // Tue
      expect(toMondayOfWeek(DateTime(2024, 1, 17)), expectedMonday); // Wed
      expect(toMondayOfWeek(DateTime(2024, 1, 18)), expectedMonday); // Thu
      expect(toMondayOfWeek(DateTime(2024, 1, 19)), expectedMonday); // Fri
      expect(toMondayOfWeek(DateTime(2024, 1, 20)), expectedMonday); // Sat
      expect(toMondayOfWeek(DateTime(2024, 1, 21)), expectedMonday); // Sun
    });
  });

  group('workoutId', () {
    test('toWorkoutId generates correct format', () {
      final date = DateTime(2024, 1, 15);
      expect(toWorkoutId('user123', date), 'user123_2024-01-15');
    });

    test('toWorkoutId handles uid with underscore', () {
      final date = DateTime(2024, 1, 15);
      expect(toWorkoutId('user_123', date), 'user_123_2024-01-15');
    });

    test('parseWorkoutId extracts uid and dateKey', () {
      final result = parseWorkoutId('user123_2024-01-15');
      expect(result, isNotNull);
      expect(result!.uid, 'user123');
      expect(result.dateKey, '2024-01-15');
    });

    test('parseWorkoutId handles uid with underscore', () {
      final result = parseWorkoutId('user_123_2024-01-15');
      expect(result, isNotNull);
      expect(result!.uid, 'user_123');
      expect(result.dateKey, '2024-01-15');
    });

    test('parseWorkoutId returns null for invalid format', () {
      expect(parseWorkoutId('invalid'), isNull);
      expect(parseWorkoutId('user123'), isNull);
      expect(parseWorkoutId('user123_invalid-date'), isNull);
    });
  });

  group('toSundayOfWeek', () {
    test('returns correct Sunday for Monday', () {
      final monday = DateTime(2024, 1, 15);
      expect(toSundayOfWeek(monday), DateTime(2024, 1, 21));
    });

    test('returns same date for Sunday', () {
      final sunday = DateTime(2024, 1, 21);
      expect(toSundayOfWeek(sunday), DateTime(2024, 1, 21));
    });
  });
}
