import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/exercise_type.dart';

class ExerciseTypeRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _typesRef(String crewId) =>
      _firestore.collection('crews').doc(crewId).collection('exerciseTypes');

  Stream<List<ExerciseType>> watchExerciseTypes(String crewId) {
    return _typesRef(crewId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ExerciseType.fromFirestore(doc)).toList());
  }

  Future<List<ExerciseType>> getExerciseTypes(String crewId) async {
    final snapshot = await _typesRef(crewId)
        .orderBy('createdAt', descending: false)
        .get();
    return snapshot.docs.map((doc) => ExerciseType.fromFirestore(doc)).toList();
  }

  Future<ExerciseType> createExerciseType(String crewId, ExerciseType type) async {
    final docRef = await _typesRef(crewId).add(type.toFirestore());
    final doc = await docRef.get();
    return ExerciseType.fromFirestore(doc);
  }

  Future<void> updateExerciseType(String crewId, String typeId, String name) async {
    await _typesRef(crewId).doc(typeId).update({'name': name});
  }

  Future<void> deleteExerciseType(String crewId, String typeId) async {
    await _typesRef(crewId).doc(typeId).delete();
  }

  Future<void> seedDefaultTypes(String crewId) async {
    final snapshot = await _typesRef(crewId).limit(1).get();
    if (snapshot.docs.isNotEmpty) return;

    final defaultTypes = ['러닝', '헬스', '수영', '자전거', '요가', '등산', '홈트'];
    final batch = _firestore.batch();

    for (final name in defaultTypes) {
      final docRef = _typesRef(crewId).doc();
      batch.set(docRef, {
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }
}
