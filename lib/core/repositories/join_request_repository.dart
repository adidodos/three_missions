import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/join_request.dart';

class JoinRequestRepository {
  final _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _requestsRef(String crewId) =>
      _firestore.collection('crews').doc(crewId).collection('joinRequests');

  Future<JoinRequest?> getRequest(String crewId, String uid) async {
    final doc = await _requestsRef(crewId).doc(uid).get();
    if (!doc.exists) return null;
    return JoinRequest.fromFirestore(doc);
  }

  Stream<JoinRequest?> watchMyRequest(String crewId, String uid) {
    return _requestsRef(crewId).doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return JoinRequest.fromFirestore(doc);
    });
  }

  Stream<List<JoinRequest>> watchPendingRequests(String crewId) {
    return _requestsRef(crewId)
        .where('status', isEqualTo: RequestStatus.pending.value)
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => JoinRequest.fromFirestore(doc)).toList());
  }

  Future<void> createRequest(String crewId, JoinRequest request) async {
    await _requestsRef(crewId).doc(request.uid).set(request.toFirestoreCreate());
  }

  Future<void> approveRequest(String crewId, String uid, String handlerUid) async {
    await _requestsRef(crewId).doc(uid).update(
      JoinRequest(
        uid: uid,
        displayName: '',
        status: RequestStatus.pending,
        createdAt: DateTime.now(),
      ).toFirestoreApprove(handlerUid),
    );
  }

  Future<void> rejectRequest(String crewId, String uid, String handlerUid) async {
    await _requestsRef(crewId).doc(uid).update(
      JoinRequest(
        uid: uid,
        displayName: '',
        status: RequestStatus.pending,
        createdAt: DateTime.now(),
      ).toFirestoreReject(handlerUid),
    );
  }
}
