import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../crew/presentation/providers/crew_provider.dart';
import '../../../logs/data/log_repository.dart';
import '../../../logs/data/models/workout_log.dart';
import '../../../../core/utils/date_utils.dart';

final logRepositoryForStatsProvider = Provider<LogRepository>((ref) {
  return LogRepository();
});

class StatsData {
  final int totalLogs;
  final Map<String, int> logsByMember;
  final Map<String, int> logsByExerciseType;
  final int streak;
  final DateTime startDate;
  final DateTime endDate;

  StatsData({
    required this.totalLogs,
    required this.logsByMember,
    required this.logsByExerciseType,
    required this.streak,
    required this.startDate,
    required this.endDate,
  });
}

class StatsNotifier extends AsyncNotifier<StatsData> {
  bool _isWeekly = true;

  bool get isWeekly => _isWeekly;

  void setWeekly(bool value) {
    _isWeekly = value;
    ref.invalidateSelf();
  }

  @override
  Future<StatsData> build() async {
    final crewId = ref.watch(currentCrewIdProvider);
    final repo = ref.watch(logRepositoryForStatsProvider);

    final today = AppDateUtils.today();
    late DateTime startDate;
    late DateTime endDate;

    if (_isWeekly) {
      startDate = AppDateUtils.startOfWeek(today);
      endDate = AppDateUtils.endOfWeek(today);
    } else {
      startDate = AppDateUtils.startOfMonth(today);
      endDate = AppDateUtils.endOfMonth(today);
    }

    final logs = await repo.getLogsByDateRange(
      crewId,
      AppDateUtils.toDateString(startDate),
      AppDateUtils.toDateString(endDate),
    );

    return _calculateStats(logs, startDate, endDate);
  }

  StatsData _calculateStats(List<WorkoutLog> logs, DateTime startDate, DateTime endDate) {
    final logsByMember = <String, int>{};
    final logsByExerciseType = <String, int>{};
    final logDates = <String>{};

    for (final log in logs) {
      logsByMember[log.memberName] = (logsByMember[log.memberName] ?? 0) + 1;
      logsByExerciseType[log.exerciseTypeName] =
          (logsByExerciseType[log.exerciseTypeName] ?? 0) + 1;
      logDates.add(log.date);
    }

    // Sort by count descending
    final sortedMembers = Map.fromEntries(
      logsByMember.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
    final sortedTypes = Map.fromEntries(
      logsByExerciseType.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );

    // Calculate streak (consecutive days)
    final streak = _calculateStreak(logDates, startDate, endDate);

    return StatsData(
      totalLogs: logs.length,
      logsByMember: sortedMembers,
      logsByExerciseType: sortedTypes,
      streak: streak,
      startDate: startDate,
      endDate: endDate,
    );
  }

  int _calculateStreak(Set<String> logDates, DateTime startDate, DateTime endDate) {
    if (logDates.isEmpty) return 0;

    final today = AppDateUtils.today();
    int streak = 0;
    var current = today;

    while (!current.isBefore(startDate)) {
      final dateStr = AppDateUtils.toDateString(current);
      if (logDates.contains(dateStr)) {
        streak++;
        current = current.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }
}

final statsNotifierProvider =
    AsyncNotifierProvider<StatsNotifier, StatsData>(() => StatsNotifier());
