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
      expect(toWeekKey(sunday), '2024-01-15');
    });

    test('Month boundary: Sunday at month end returns Monday from previous month', () {
      // 2024-03-03 is Sunday, Monday is 2024-02-26
      final sunday = DateTime(2024, 3, 3);
      expect(sunday.weekday, DateTime.sunday);
      expect(toWeekKey(sunday), '2024-02-26');
    });
  });

  group('workoutId', () {
    test('toWorkoutId generates correct format', () {
      final date = DateTime(2024, 1, 15);
      expect(toWorkoutId('user123', date), 'user123_2024-01-15');
    });

    test('parseWorkoutId extracts uid and dateKey', () {
      final result = parseWorkoutId('user123_2024-01-15');
      expect(result, isNotNull);
      expect(result!.uid, 'user123');
      expect(result.dateKey, '2024-01-15');
    });

    test('workoutId enforces one per day - same uid+date = same id', () {
      final date = DateTime(2024, 1, 15);
      final id1 = toWorkoutId('user123', date);
      final id2 = toWorkoutId('user123', date);
      expect(id1, id2); // Same ID means only one document per day
    });
  });

  group('getWeekDates', () {
    test('returns 7 dates starting from Monday', () {
      final dates = getWeekDates(DateTime(2024, 1, 17)); // Wednesday
      expect(dates.length, 7);
      expect(dates.first.weekday, DateTime.monday);
      expect(dates.last.weekday, DateTime.sunday);
      expect(toDateKey(dates.first), '2024-01-15');
      expect(toDateKey(dates.last), '2024-01-21');
    });
  });
}
