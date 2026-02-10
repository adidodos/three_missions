import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/workout.dart';
import '../utils/date_keys.dart';

class WorkoutRepository {
  final _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _workoutsRef(String crewId) =>
      _firestore.collection('crews').doc(crewId).collection('workouts');

  Future<Workout?> getWorkout(String crewId, String workoutId) async {
    final doc = await _workoutsRef(crewId).doc(workoutId).get();
    if (!doc.exists) return null;
    return Workout.fromFirestore(doc);
  }

  Future<Workout?> getTodayWorkout(String crewId, String uid) async {
    final workoutId = toWorkoutId(uid, today());
    return getWorkout(crewId, workoutId);
  }

  Stream<Workout?> watchTodayWorkout(String crewId, String uid) {
    final workoutId = toWorkoutId(uid, today());
    return _workoutsRef(crewId).doc(workoutId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Workout.fromFirestore(doc);
    });
  }

  /// Get workouts for a week (by weekKey)
  Future<List<Workout>> getWeekWorkouts(String crewId, String weekKey) async {
    final snapshot = await _workoutsRef(crewId)
        .where('weekKey', isEqualTo: weekKey)
        .get();
    return snapshot.docs.map((doc) => Workout.fromFirestore(doc)).toList();
  }

  Stream<List<Workout>> watchWeekWorkouts(String crewId, String weekKey) {
    return _workoutsRef(crewId)
        .where('weekKey', isEqualTo: weekKey)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Workout.fromFirestore(doc)).toList());
  }

  /// Get my workouts for a week
  Future<List<Workout>> getMyWeekWorkouts(String crewId, String uid, String weekKey) async {
    final snapshot = await _workoutsRef(crewId)
        .where('uid', isEqualTo: uid)
        .where('weekKey', isEqualTo: weekKey)
        .get();
    return snapshot.docs.map((doc) => Workout.fromFirestore(doc)).toList();
  }

  /// Get my workouts for a month
  Future<List<Workout>> getMyMonthWorkouts(
    String crewId,
    String uid,
    String startDateKey,
    String endDateKey,
  ) async {
    final snapshot = await _workoutsRef(crewId)
        .where('uid', isEqualTo: uid)
        .where('dateKey', isGreaterThanOrEqualTo: startDateKey)
        .where('dateKey', isLessThanOrEqualTo: endDateKey)
        .get();
    return snapshot.docs.map((doc) => Workout.fromFirestore(doc)).toList();
  }

  Future<void> createWorkout(String crewId, Workout workout) async {
    await _workoutsRef(crewId).doc(workout.id).set(workout.toFirestoreCreate());
  }

  Future<void> updateWorkout(String crewId, Workout workout) async {
    await _workoutsRef(crewId).doc(workout.id).update(workout.toFirestoreUpdate());
  }

  Future<void> deleteWorkout(String crewId, String workoutId) async {
    await _workoutsRef(crewId).doc(workoutId).delete();
  }
}
