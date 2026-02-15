import 'date_keys.dart';

/// 날짜별 미션 인증 상태.
enum MissionStatus {
  /// 인증 완료 (O)
  completed,

  /// 미인증 (X) — 과거 날짜에만 해당
  missed,

  /// 표기 없음 — 당일 미인증 또는 미래 날짜
  none,
}

/// 날짜와 인증 기록 유무를 기반으로 [MissionStatus]를 판정한다.
///
/// - 과거: 기록 있음 → [MissionStatus.completed], 없음 → [MissionStatus.missed]
/// - 당일: 기록 있음 → [MissionStatus.completed], 없음 → [MissionStatus.none]
/// - 미래: 항상 [MissionStatus.none]
MissionStatus getMissionStatus({
  required DateTime date,
  required bool hasRecord,
}) {
  final now = today();
  final dateOnly = DateTime(date.year, date.month, date.day);

  if (dateOnly.isAfter(now)) {
    // 미래
    return MissionStatus.none;
  }

  if (dateOnly.isBefore(now)) {
    // 과거
    return hasRecord ? MissionStatus.completed : MissionStatus.missed;
  }

  // 당일
  return hasRecord ? MissionStatus.completed : MissionStatus.none;
}
