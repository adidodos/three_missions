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

  /// Get all join requests for a user across all crews (pending + rejected).
  Future<List<({JoinRequest request, String crewId})>> getMyJoinRequests(String uid) async {
    final snapshot = await _firestore
        .collectionGroup('joinRequests')
        .where('uid', isEqualTo: uid)
        .get();

    final results = <({JoinRequest request, String crewId})>[];
    for (final doc in snapshot.docs) {
      final request = JoinRequest.fromFirestore(doc);
      // Only include pending and rejected (not approved)
      if (request.status == RequestStatus.approved) continue;
      // Path: crews/{crewId}/joinRequests/{uid}
      final crewId = doc.reference.parent.parent?.id;
      if (crewId != null) {
        results.add((request: request, crewId: crewId));
      }
    }
    return results;
  }

  Future<void> deleteRequest(String crewId, String uid) async {
    await _requestsRef(crewId).doc(uid).delete();
  }

  /// Re-apply: delete rejected request and create a new pending one.
  /// Must be sequential (not batch) because Firestore evaluates batch
  /// security rules against pre-batch state, causing the set to be
  /// treated as an update (which requires admin permission).
  Future<void> reapplyRequest(String crewId, JoinRequest request) async {
    final docRef = _requestsRef(crewId).doc(request.uid);
    await docRef.delete();
    await docRef.set(request.toFirestoreCreate());
  }

  /// Delete all join requests for a user across all crews (for account deletion).
  Future<void> removeUserRequestsFromAllCrews(String uid) async {
    final snapshot = await _firestore
        .collectionGroup('joinRequests')
        .where('uid', isEqualTo: uid)
        .get();

    if (snapshot.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
