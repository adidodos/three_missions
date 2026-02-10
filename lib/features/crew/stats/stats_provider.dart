import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/repositories/workout_repository.dart';
import '../../../core/utils/date_keys.dart';

final statsWorkoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  return WorkoutRepository();
});

class WeeklyStats {
  final int count;
  final bool isSuccess;
  final int streak;
  final List<String> workoutDates;

  WeeklyStats({
    required this.count,
    required this.isSuccess,
    required this.streak,
    required this.workoutDates,
  });
}

class MonthlyStats {
  final int totalCount;
  final int successfulWeeks;
  final int totalWeeks;
  final Map<String, int> typeDistribution;

  MonthlyStats({
    required this.totalCount,
    required this.successfulWeeks,
    required this.totalWeeks,
    required this.typeDistribution,
  });
}

final myWeeklyStatsProvider = FutureProvider.family<WeeklyStats, String>((ref, crewId) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return WeeklyStats(count: 0, isSuccess: false, streak: 0, workoutDates: []);
  }

  final repo = ref.read(statsWorkoutRepositoryProvider);
  final workouts = await repo.getMyWeekWorkouts(crewId, user.uid, thisWeekKey());

  // Calculate streak
  int streak = 0;
  var checkDate = today();
  while (true) {
    final dateKey = toDateKey(checkDate);
    final hasWorkout = workouts.any((w) => w.dateKey == dateKey);
    if (hasWorkout) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    } else {
      break;
    }
  }

  return WeeklyStats(
    count: workouts.length,
    isSuccess: workouts.length >= 3,
    streak: streak,
    workoutDates: workouts.map((w) => w.dateKey).toList(),
  );
});

final myMonthlyStatsProvider = FutureProvider.family<MonthlyStats, String>((ref, crewId) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return MonthlyStats(
      totalCount: 0,
      successfulWeeks: 0,
      totalWeeks: 0,
      typeDistribution: {},
    );
  }

  final repo = ref.read(statsWorkoutRepositoryProvider);
  final (startDate, endDate) = getMonthRange(today());

  final workouts = await repo.getMyMonthWorkouts(
    crewId,
    user.uid,
    toDateKey(startDate),
    toDateKey(endDate),
  );

  // Calculate type distribution
  final typeDistribution = <String, int>{};
  for (final w in workouts) {
    typeDistribution[w.type] = (typeDistribution[w.type] ?? 0) + 1;
  }

  // Calculate successful weeks
  final weekWorkouts = <String, int>{};
  for (final w in workouts) {
    weekWorkouts[w.weekKey] = (weekWorkouts[w.weekKey] ?? 0) + 1;
  }
  final successfulWeeks = weekWorkouts.values.where((count) => count >= 3).length;

  return MonthlyStats(
    totalCount: workouts.length,
    successfulWeeks: successfulWeeks,
    totalWeeks: weekWorkouts.length,
    typeDistribution: typeDistribution,
  );
});
