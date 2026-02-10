import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/firestore_converters.dart';

enum MemberRole {
  owner('OWNER'),
  admin('ADMIN'),
  member('MEMBER');

  final String value;
  const MemberRole(this.value);

  static MemberRole fromString(String? value) {
    return MemberRole.values.firstWhere(
      (r) => r.value == value,
      orElse: () => MemberRole.member,
    );
  }

  bool get isAdmin => this == MemberRole.owner || this == MemberRole.admin;
}

enum MemberStatus {
  active('ACTIVE'),
  banned('BANNED');

  final String value;
  const MemberStatus(this.value);

  static MemberStatus fromString(String? value) {
    return MemberStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => MemberStatus.active,
    );
  }
}

/// Member: /crews/{crewId}/members/{uid}
class Member {
  final String uid;
  final String displayName;
  final String? photoUrl;
  final MemberRole role;
  final MemberStatus status;
  final DateTime joinedAt;

  const Member({
    required this.uid,
    required this.displayName,
    this.photoUrl,
    required this.role,
    this.status = MemberStatus.active,
    required this.joinedAt,
  });

  factory Member.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Member(
      uid: doc.id,
      displayName: data['displayName'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      role: MemberRole.fromString(data['role'] as String?),
      status: MemberStatus.fromString(data['status'] as String?),
      joinedAt: timestampToDateTime(data['joinedAt'] as Timestamp?),
    );
  }

  Map<String, dynamic> toFirestoreCreate() => {
    'uid': uid,
    'displayName': displayName,
    if (photoUrl != null) 'photoUrl': photoUrl,
    'role': role.value,
    'status': status.value,
    'joinedAt': serverTimestamp,
  };

  Map<String, dynamic> toFirestoreUpdate() => {
    'displayName': displayName,
    if (photoUrl != null) 'photoUrl': photoUrl,
    'role': role.value,
    'status': status.value,
  };

  Member copyWith({
    String? uid,
    String? displayName,
    String? photoUrl,
    MemberRole? role,
    MemberStatus? status,
    DateTime? joinedAt,
  }) => Member(
    uid: uid ?? this.uid,
    displayName: displayName ?? this.displayName,
    photoUrl: photoUrl ?? this.photoUrl,
    role: role ?? this.role,
    status: status ?? this.status,
    joinedAt: joinedAt ?? this.joinedAt,
  );
}
