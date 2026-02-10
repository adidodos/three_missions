import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/crew.dart';
import '../models/member.dart';

class CrewRepository {
  final _firestore = FirebaseFirestore.instance;

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

  Future<List<Crew>> getMyCrews(String uid) async {
    // Get all crews where user is a member
    final crewsWithMember = <Crew>[];

    // This requires a collection group query
    final memberDocs = await _firestore
        .collectionGroup('members')
        .where('uid', isEqualTo: uid)
        .where('status', isEqualTo: MemberStatus.active.value)
        .get();

    for (final memberDoc in memberDocs.docs) {
      // Path: crews/{crewId}/members/{uid}
      final crewId = memberDoc.reference.parent.parent?.id;
      if (crewId != null) {
        final crew = await getCrew(crewId);
        if (crew != null) {
          crewsWithMember.add(crew);
        }
      }
    }

    return crewsWithMember;
  }

  Future<String> createCrew(String name, String ownerUid, String ownerName, String? photoUrl) async {
    // Create crew
    final crewRef = _crewsRef.doc();
    final crew = Crew(
      id: crewRef.id,
      name: name,
      ownerUid: ownerUid,
      createdAt: DateTime.now(),
    );
    await crewRef.set(crew.toFirestoreCreate());

    // Add owner as first member
    final member = Member(
      uid: ownerUid,
      displayName: ownerName,
      photoUrl: photoUrl,
      role: MemberRole.owner,
      status: MemberStatus.active,
      joinedAt: DateTime.now(),
    );
    await crewRef.collection('members').doc(ownerUid).set(member.toFirestoreCreate());

    return crewRef.id;
  }
}
