import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/member.dart';

class MemberRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _membersRef(String crewId) =>
      _firestore.collection('crews').doc(crewId).collection('members');

  Stream<List<Member>> watchMembers(String crewId) {
    return _membersRef(crewId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Member.fromFirestore(doc)).toList());
  }

  Future<List<Member>> getMembers(String crewId) async {
    final snapshot = await _membersRef(crewId)
        .orderBy('createdAt', descending: false)
        .get();
    return snapshot.docs.map((doc) => Member.fromFirestore(doc)).toList();
  }

  Future<Member?> getMyMember(String crewId, String uid) async {
    final snapshot =
        await _membersRef(crewId).where('uid', isEqualTo: uid).limit(1).get();
    if (snapshot.docs.isEmpty) return null;
    return Member.fromFirestore(snapshot.docs.first);
  }

  Future<Member> createMember(String crewId, Member member) async {
    final docRef = await _membersRef(crewId).add(member.toFirestore());
    final doc = await docRef.get();
    return Member.fromFirestore(doc);
  }

  Future<void> updateMember(String crewId, String memberId, String name) async {
    await _membersRef(crewId).doc(memberId).update({'name': name});
  }

  Future<void> deleteMember(String crewId, String memberId) async {
    await _membersRef(crewId).doc(memberId).delete();
  }

  Future<Member> ensureMyMember(String crewId, String uid) async {
    final existing = await getMyMember(crewId, uid);
    if (existing != null) return existing;

    final newMember = Member(
      id: '',
      name: '나',
      uid: uid,
      isMe: true,
      createdAt: DateTime.now(),
    );
    return await createMember(crewId, newMember);
  }
}
