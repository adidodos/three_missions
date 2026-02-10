import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/repositories/member_repository.dart';
import '../../../core/repositories/workout_repository.dart';
import '../../../core/models/member.dart';
import '../../../core/models/workout.dart';
import '../../../core/utils/date_keys.dart';

final tableMemberRepositoryProvider = Provider<MemberRepository>((ref) {
  return MemberRepository();
});

final tableWorkoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  return WorkoutRepository();
});

final crewMembersProvider = StreamProvider.family<List<Member>, String>((ref, crewId) {
  final repo = ref.read(tableMemberRepositoryProvider);
  return repo.watchMembers(crewId);
});

final weekWorkoutsProvider = StreamProvider.family<List<Workout>, String>((ref, crewId) {
  final repo = ref.read(tableWorkoutRepositoryProvider);
  return repo.watchWeekWorkouts(crewId, thisWeekKey());
});

/// Selected week offset notifier (0 = this week, -1 = last week, etc.)
class WeekOffsetNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void increment() {
    if (state < 0) state++;
  }

  void decrement() {
    state--;
  }
}

final selectedWeekOffsetProvider = NotifierProvider<WeekOffsetNotifier, int>(
  WeekOffsetNotifier.new,
);

/// Get workouts for selected week
final selectedWeekWorkoutsProvider = FutureProvider.family<List<Workout>, String>((ref, crewId) async {
  final offset = ref.watch(selectedWeekOffsetProvider);
  final selectedDate = today().add(Duration(days: offset * 7));
  final weekKey = toWeekKey(selectedDate);

  final repo = ref.read(tableWorkoutRepositoryProvider);
  return await repo.getWeekWorkouts(crewId, weekKey);
});
