import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/member.dart';

class MemberRepository {
  final FirebaseFirestore _firestore;

  MemberRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _membersRef(String crewId) =>
      _firestore.collection('crews').doc(crewId).collection('members');

  Future<Member?> getMember(String crewId, String uid) async {
    final doc = await _membersRef(crewId).doc(uid).get();
    if (!doc.exists) return null;
    return Member.fromFirestore(doc);
  }

  Stream<Member?> watchMember(String crewId, String uid) {
    return _membersRef(crewId).doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Member.fromFirestore(doc);
    });
  }

  Stream<List<Member>> watchMembers(String crewId) {
    return _membersRef(crewId)
        .where('status', isEqualTo: MemberStatus.active.value)
        .orderBy('joinedAt')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Member.fromFirestore(doc)).toList());
  }

  Future<List<Member>> getMembers(String crewId) async {
    final snapshot = await _membersRef(crewId)
        .where('status', isEqualTo: MemberStatus.active.value)
        .orderBy('joinedAt')
        .get();
    return snapshot.docs.map((doc) => Member.fromFirestore(doc)).toList();
  }

  Future<void> addMember(String crewId, Member member) async {
    await _membersRef(crewId).doc(member.uid).set(member.toFirestoreCreate());
  }

  Future<void> updateMemberRole(String crewId, String uid, MemberRole role) async {
    await _membersRef(crewId).doc(uid).update({'role': role.value});
  }

  Future<void> banMember(String crewId, String uid) async {
    await _membersRef(crewId).doc(uid).update({
      'status': MemberStatus.banned.value,
    });
  }

  Future<void> removeMember(String crewId, String uid) async {
    await _membersRef(crewId).doc(uid).delete();
  }

  Future<void> updatePhotoUrlInAllCrews(String uid, String photoUrl) async {
    final memberDocs = await _firestore
        .collectionGroup('members')
        .where('uid', isEqualTo: uid)
        .get();

    final batch = _firestore.batch();
    for (final doc in memberDocs.docs) {
      batch.update(doc.reference, {'photoUrl': photoUrl});
    }
    await batch.commit();
  }

  Future<void> updateDisplayNameInAllCrews(String uid, String displayName) async {
    final memberDocs = await _firestore
        .collectionGroup('members')
        .where('uid', isEqualTo: uid)
        .get();

    final batch = _firestore.batch();
    for (final doc in memberDocs.docs) {
      batch.update(doc.reference, {'displayName': displayName});
    }
    await batch.commit();
  }

  /// Get all member documents for a user (for account deletion - to find crew IDs).
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> getUserMemberDocs(String uid) async {
    final snapshot = await _firestore
        .collectionGroup('members')
        .where('uid', isEqualTo: uid)
        .get();
    return snapshot.docs;
  }

  /// Returns crew IDs where the user is the owner
  Future<List<String>> getOwnedCrewIds(String uid) async {
    // Query by uid only (collectionGroup index exists for uid),
    // then filter role client-side to avoid needing a composite index.
    final memberDocs = await _firestore
        .collectionGroup('members')
        .where('uid', isEqualTo: uid)
        .get();

    return memberDocs.docs
        .where((doc) => doc.data()['role'] == MemberRole.owner.value)
        .map((doc) => doc.reference.parent.parent?.id)
        .whereType<String>()
        .toList();
  }

  /// Remove user from all crews (for account deletion)
  Future<void> removeUserFromAllCrews(String uid) async {
    final memberDocs = await _firestore
        .collectionGroup('members')
        .where('uid', isEqualTo: uid)
        .get();

    final batch = _firestore.batch();
    for (final doc in memberDocs.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
