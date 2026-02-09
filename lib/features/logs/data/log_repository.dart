import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/workout_log.dart';

class LogRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _logsRef(String crewId) =>
      _firestore.collection('crews').doc(crewId).collection('logs');

  Stream<List<WorkoutLog>> watchLogs(String crewId) {
    return _logsRef(crewId)
        .orderBy('date', descending: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => WorkoutLog.fromFirestore(doc)).toList());
  }

  Stream<List<WorkoutLog>> watchLogsByDate(String crewId, String date) {
    return _logsRef(crewId)
        .where('date', isEqualTo: date)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => WorkoutLog.fromFirestore(doc)).toList());
  }

  Future<List<WorkoutLog>> getLogs(String crewId) async {
    final snapshot = await _logsRef(crewId)
        .orderBy('date', descending: true)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => WorkoutLog.fromFirestore(doc)).toList();
  }

  Future<List<WorkoutLog>> getLogsByDateRange(
      String crewId, String startDate, String endDate) async {
    final snapshot = await _logsRef(crewId)
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate)
        .orderBy('date', descending: true)
        .get();
    return snapshot.docs.map((doc) => WorkoutLog.fromFirestore(doc)).toList();
  }

  Future<WorkoutLog> createLog(String crewId, WorkoutLog log) async {
    final docRef = await _logsRef(crewId).add(log.toFirestore());
    final doc = await docRef.get();
    return WorkoutLog.fromFirestore(doc);
  }

  Future<void> updateLog(String crewId, WorkoutLog log) async {
    await _logsRef(crewId).doc(log.id).update({
      'memberId': log.memberId,
      'memberName': log.memberName,
      'exerciseTypeId': log.exerciseTypeId,
      'exerciseTypeName': log.exerciseTypeName,
      'date': log.date,
      'memo': log.memo,
      'durationMinutes': log.durationMinutes,
    });
  }

  Future<void> deleteLog(String crewId, String logId) async {
    await _logsRef(crewId).doc(logId).delete();
  }
}
