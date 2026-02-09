import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/firestore_converters.dart';

/// Join request status.
enum JoinRequestStatus {
  /// Waiting for approval
  pending,

  /// Approved (user is now a member)
  approved,

  /// Rejected by admin/owner
  rejected,
}

/// Join request model for crew membership.
///
/// Firestore path: crews/{crewId}/joinRequests/{uid}
/// Document ID: Requesting user's UID
class JoinRequest {
  /// Requesting user's UID (document ID)
  final String uid;

  /// User's display name
  final String displayName;

  /// User's photo URL (optional)
  final String? photoUrl;

  /// Request status
  final JoinRequestStatus status;

  /// Optional message from the user
  final String? message;

  /// Request creation timestamp
  final DateTime requestedAt;

  /// Status update timestamp (approval/rejection time)
  final DateTime? processedAt;

  /// UID of admin/owner who processed the request
  final String? processedBy;

  const JoinRequest({
    required this.uid,
    required this.displayName,
    this.photoUrl,
    required this.status,
    this.message,
    required this.requestedAt,
    this.processedAt,
    this.processedBy,
  });

  factory JoinRequest.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return JoinRequest(
      uid: doc.id,
      displayName: data['displayName'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      status: _parseStatus(data['status'] as String?),
      message: data['message'] as String?,
      requestedAt: timestampToDateTime(data['requestedAt'] as Timestamp?),
      processedAt: timestampToDateTimeNullable(data['processedAt'] as Timestamp?),
      processedBy: data['processedBy'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      if (photoUrl != null) 'photoUrl': photoUrl,
      'status': status.name,
      if (message != null) 'message': message,
      'requestedAt': dateTimeToTimestamp(requestedAt),
      if (processedAt != null) 'processedAt': dateTimeToTimestamp(processedAt!),
      if (processedBy != null) 'processedBy': processedBy,
    };
  }

  Map<String, dynamic> toFirestoreCreate() {
    return {
      'displayName': displayName,
      if (photoUrl != null) 'photoUrl': photoUrl,
      'status': JoinRequestStatus.pending.name,
      if (message != null) 'message': message,
      'requestedAt': serverTimestamp,
    };
  }

  static JoinRequestStatus _parseStatus(String? value) {
    return JoinRequestStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => JoinRequestStatus.pending,
    );
  }

  JoinRequest copyWith({
    String? uid,
    String? displayName,
    String? photoUrl,
    JoinRequestStatus? status,
    String? message,
    DateTime? requestedAt,
    DateTime? processedAt,
    String? processedBy,
  }) {
    return JoinRequest(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      status: status ?? this.status,
      message: message ?? this.message,
      requestedAt: requestedAt ?? this.requestedAt,
      processedAt: processedAt ?? this.processedAt,
      processedBy: processedBy ?? this.processedBy,
    );
  }

  @override
  String toString() => 'JoinRequest(uid: $uid, status: ${status.name})';
}
