import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/crew.dart';
import '../models/crew_settings.dart';
import '../models/member.dart';

class CrewRepository {
  final FirebaseFirestore _firestore;

  CrewRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _crewsRef =>
      _firestore.collection('crews');

  Future<Crew?> getCrew(String crewId) async {
    final doc = await _crewsRef.doc(crewId).get();
    if (!doc.exists) return null;
    return Crew.fromFirestore(doc);
  }

  Future<List<Crew>> searchCrews(String query) async {
    if (query.isEmpty) return [];

    // Firestore doesn't support full-text search, so we use prefix matching
    final snapshot = await _crewsRef
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .limit(20)
        .get();

    return snapshot.docs.map((doc) => Crew.fromFirestore(doc)).toList();
  }

  Stream<List<Crew>> watchMyCrews(String uid) {
    return _firestore
        .collectionGroup('members')
        .where('uid', isEqualTo: uid)
        .where('status', isEqualTo: MemberStatus.active.value)
        .snapshots()
        .asyncMap((snapshot) async {
      final crews = <Crew>[];
      for (final doc in snapshot.docs) {
        final crewId = doc.reference.parent.parent?.id;
        if (crewId != null) {
          final crew = await getCrew(crewId);
          if (crew != null) {
            crews.add(crew);
          }
        }
      }
      return crews;
    });
  }

  Future<bool> isNameTaken(String name) async {
    final snapshot = await _crewsRef
        .where('name', isEqualTo: name)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  Future<String> createCrew(String name, String ownerUid, String ownerName, String? photoUrl) async {
    if (await isNameTaken(name)) {
      throw CrewNameTakenException(name);
    }

    final crewRef = _crewsRef.doc();
    final crew = Crew(
      id: crewRef.id,
      name: name,
      ownerUid: ownerUid,
      createdAt: DateTime.now(),
    );
    final member = Member(
      uid: ownerUid,
      displayName: ownerName,
      photoUrl: photoUrl,
      role: MemberRole.owner,
      status: MemberStatus.active,
      joinedAt: DateTime.now(),
    );

    // Batch write: create crew + owner member atomically
    final batch = _firestore.batch();
    batch.set(crewRef, crew.toFirestoreCreate());
    batch.set(crewRef.collection('members').doc(ownerUid), member.toFirestoreCreate());
    await batch.commit();

    return crewRef.id;
  }

  Future<void> updateSettings(String crewId, CrewSettings settings) async {
    await _crewsRef.doc(crewId).update({
      'settings': settings.toMap(),
    });
  }

  Future<void> transferOwnership(String crewId, String oldOwnerUid, String newOwnerUid) async {
    final batch = _firestore.batch();
    batch.update(_crewsRef.doc(crewId), {'ownerUid': newOwnerUid});
    batch.update(
      _crewsRef.doc(crewId).collection('members').doc(oldOwnerUid),
      {'role': MemberRole.member.value},
    );
    batch.update(
      _crewsRef.doc(crewId).collection('members').doc(newOwnerUid),
      {'role': MemberRole.owner.value},
    );
    await batch.commit();
  }

  Future<void> deleteCrew(String crewId) async {
    final membersSnapshot =
        await _crewsRef.doc(crewId).collection('members').get();

    final batch = _firestore.batch();
    for (final doc in membersSnapshot.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_crewsRef.doc(crewId));
    await batch.commit();
  }
}

class CrewNameTakenException implements Exception {
  final String name;
  const CrewNameTakenException(this.name);

  @override
  String toString() => '이미 사용 중인 크루 이름입니다: $name';
}
