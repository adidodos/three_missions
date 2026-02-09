import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/firestore_converters.dart';

/// Crew (운동 크루) model.
///
/// Firestore path: crews/{crewId}
/// Document ID: Auto-generated or custom slug
///
/// Subcollections:
/// - crews/{crewId}/members/{uid}
/// - crews/{crewId}/joinRequests/{uid}
/// - crews/{crewId}/workouts/{workoutId}
class Crew {
  /// Crew document ID
  final String id;

  /// Crew display name
  final String name;

  /// Crew description (optional)
  final String? description;

  /// Owner's UID (crew creator)
  final String ownerUid;

  /// Invite code for joining (optional)
  final String? inviteCode;

  /// Creation timestamp
  final DateTime createdAt;

  /// Last update timestamp
  final DateTime updatedAt;

  const Crew({
    required this.id,
    required this.name,
    this.description,
    required this.ownerUid,
    this.inviteCode,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Crew.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Crew(
      id: doc.id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String?,
      ownerUid: data['ownerUid'] as String? ?? '',
      inviteCode: data['inviteCode'] as String?,
      createdAt: timestampToDateTime(data['createdAt'] as Timestamp?),
      updatedAt: timestampToDateTime(data['updatedAt'] as Timestamp?),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      if (description != null) 'description': description,
      'ownerUid': ownerUid,
      if (inviteCode != null) 'inviteCode': inviteCode,
      'createdAt': dateTimeToTimestamp(createdAt),
      'updatedAt': serverTimestamp,
    };
  }

  Map<String, dynamic> toFirestoreCreate() {
    return {
      'name': name,
      if (description != null) 'description': description,
      'ownerUid': ownerUid,
      if (inviteCode != null) 'inviteCode': inviteCode,
      'createdAt': serverTimestamp,
      'updatedAt': serverTimestamp,
    };
  }

  Crew copyWith({
    String? id,
    String? name,
    String? description,
    String? ownerUid,
    String? inviteCode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Crew(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      ownerUid: ownerUid ?? this.ownerUid,
      inviteCode: inviteCode ?? this.inviteCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'Crew(id: $id, name: $name, ownerUid: $ownerUid)';
}
