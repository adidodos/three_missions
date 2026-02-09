import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/crew.dart';

class CrewRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String defaultCrewId = 'default';

  CollectionReference<Map<String, dynamic>> get _crewsRef =>
      _firestore.collection('crews');

  Future<Crew?> getCrew(String crewId) async {
    final doc = await _crewsRef.doc(crewId).get();
    if (!doc.exists) return null;
    return Crew.fromFirestore(doc);
  }

  Future<void> createDefaultCrew(String ownerUid) async {
    final doc = await _crewsRef.doc(defaultCrewId).get();
    if (doc.exists) return;

    await _crewsRef.doc(defaultCrewId).set({
      'name': '우리 크루',
      'ownerUid': ownerUid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
