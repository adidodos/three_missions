import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/member.dart';

class MemberRepository {
  final _firestore = FirebaseFirestore.instance;

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
}
