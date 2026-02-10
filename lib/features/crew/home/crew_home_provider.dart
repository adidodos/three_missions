import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/repositories/crew_repository.dart';
import '../../../core/repositories/workout_repository.dart';
import '../../../core/models/crew.dart';
import '../../../core/models/workout.dart';
import '../../../core/utils/date_keys.dart';

final crewHomeRepositoryProvider = Provider<CrewRepository>((ref) {
  return CrewRepository();
});

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  return WorkoutRepository();
});

final crewDetailProvider = FutureProvider.family<Crew?, String>((ref, crewId) async {
  final repo = ref.read(crewHomeRepositoryProvider);
  return await repo.getCrew(crewId);
});

final todayWorkoutProvider = StreamProvider.family<Workout?, String>((ref, crewId) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);

  final repo = ref.read(workoutRepositoryProvider);
  return repo.watchTodayWorkout(crewId, user.uid);
});

final myWeekWorkoutsProvider = FutureProvider.family<List<Workout>, String>((ref, crewId) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final repo = ref.read(workoutRepositoryProvider);
  return await repo.getMyWeekWorkouts(crewId, user.uid, thisWeekKey());
});
