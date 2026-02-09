import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/firestore_converters.dart';

/// Member role within a crew.
enum MemberRole {
  /// Crew owner (full permissions)
  owner,

  /// Admin (can manage members)
  admin,

  /// Regular member
  member,
}

/// Crew member model.
///
/// Firestore path: crews/{crewId}/members/{uid}
/// Document ID: User's Firebase Auth UID
class Member {
  /// User's UID (document ID)
  final String uid;

  /// Display name (copied from UserProfile for denormalization)
  final String displayName;

  /// Profile photo URL (optional)
  final String? photoUrl;

  /// Member role in this crew
  final MemberRole role;

  /// Join timestamp
  final DateTime joinedAt;

  const Member({
    required this.uid,
    required this.displayName,
    this.photoUrl,
    required this.role,
    required this.joinedAt,
  });

  factory Member.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Member(
      uid: doc.id,
      displayName: data['displayName'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      role: _parseRole(data['role'] as String?),
      joinedAt: timestampToDateTime(data['joinedAt'] as Timestamp?),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      if (photoUrl != null) 'photoUrl': photoUrl,
      'role': role.name,
      'joinedAt': dateTimeToTimestamp(joinedAt),
    };
  }

  Map<String, dynamic> toFirestoreCreate() {
    return {
      'displayName': displayName,
      if (photoUrl != null) 'photoUrl': photoUrl,
      'role': role.name,
      'joinedAt': serverTimestamp,
    };
  }

  static MemberRole _parseRole(String? value) {
    return MemberRole.values.firstWhere(
      (r) => r.name == value,
      orElse: () => MemberRole.member,
    );
  }

  Member copyWith({
    String? uid,
    String? displayName,
    String? photoUrl,
    MemberRole? role,
    DateTime? joinedAt,
  }) {
    return Member(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  @override
  String toString() => 'Member(uid: $uid, displayName: $displayName, role: ${role.name})';
}
