import 'package:flutter_test/flutter_test.dart';
import 'package:three_missions/core/utils/mission_status.dart';

void main() {
  group('getMissionStatus', () {
    // 테스트용 기준일: 실행 시점의 today()를 기반으로 과거/당일/미래를 계산
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final yesterday = todayDate.subtract(const Duration(days: 1));
    final tomorrow = todayDate.add(const Duration(days: 1));

    // ── 시나리오 1: 과거 날짜 ──
    test('과거 + 기록 있음 → completed (O)', () {
      final status = getMissionStatus(date: yesterday, hasRecord: true);
      expect(status, MissionStatus.completed);
    });

    test('과거 + 기록 없음 → missed (X)', () {
      final status = getMissionStatus(date: yesterday, hasRecord: false);
      expect(status, MissionStatus.missed);
    });

    // ── 시나리오 2: 당일 ──
    test('당일 + 기록 있음 → completed (O)', () {
      final status = getMissionStatus(date: todayDate, hasRecord: true);
      expect(status, MissionStatus.completed);
    });

    test('당일 + 기록 없음 → none (표기 없음)', () {
      final status = getMissionStatus(date: todayDate, hasRecord: false);
      expect(status, MissionStatus.none);
    });

    // ── 시나리오 3: 미래 날짜 ──
    test('미래 + 기록 있음이라도 → none (표기 없음)', () {
      final status = getMissionStatus(date: tomorrow, hasRecord: true);
      expect(status, MissionStatus.none);
    });

    test('미래 + 기록 없음 → none (표기 없음)', () {
      final status = getMissionStatus(date: tomorrow, hasRecord: false);
      expect(status, MissionStatus.none);
    });
  });
}
