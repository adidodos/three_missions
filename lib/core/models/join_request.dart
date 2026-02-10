import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/firestore_converters.dart';

enum RequestStatus {
  pending('PENDING'),
  approved('APPROVED'),
  rejected('REJECTED');

  final String value;
  const RequestStatus(this.value);

  static RequestStatus fromString(String? value) {
    return RequestStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => RequestStatus.pending,
    );
  }
}

/// JoinRequest: /crews/{crewId}/joinRequests/{uid}
class JoinRequest {
  final String uid;
  final String displayName;
  final String? photoUrl;
  final RequestStatus status;
  final DateTime createdAt;
  final String? handledBy;
  final DateTime? handledAt;

  const JoinRequest({
    required this.uid,
    required this.displayName,
    this.photoUrl,
    required this.status,
    required this.createdAt,
    this.handledBy,
    this.handledAt,
  });

  factory JoinRequest.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return JoinRequest(
      uid: doc.id,
      displayName: data['displayName'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      status: RequestStatus.fromString(data['status'] as String?),
      createdAt: timestampToDateTime(data['createdAt'] as Timestamp?),
      handledBy: data['handledBy'] as String?,
      handledAt: timestampToDateTimeNullable(data['handledAt'] as Timestamp?),
    );
  }

  Map<String, dynamic> toFirestoreCreate() => {
    'uid': uid,
    'displayName': displayName,
    if (photoUrl != null) 'photoUrl': photoUrl,
    'status': RequestStatus.pending.value,
    'createdAt': serverTimestamp,
  };

  Map<String, dynamic> toFirestoreApprove(String handlerUid) => {
    'status': RequestStatus.approved.value,
    'handledBy': handlerUid,
    'handledAt': serverTimestamp,
  };

  Map<String, dynamic> toFirestoreReject(String handlerUid) => {
    'status': RequestStatus.rejected.value,
    'handledBy': handlerUid,
    'handledAt': serverTimestamp,
  };
}
