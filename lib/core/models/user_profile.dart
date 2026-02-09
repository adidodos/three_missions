import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/firestore_converters.dart';

/// User profile stored in /users/{uid}
///
/// Firestore path: users/{uid}
/// Document ID: Firebase Auth UID
class UserProfile {
  /// Firebase Auth UID (document ID)
  final String uid;

  /// Display name
  final String displayName;

  /// Profile photo URL (optional)
  final String? photoUrl;

  /// Email (optional, for Google sign-in)
  final String? email;

  /// Currently joined crew ID (optional)
  final String? currentCrewId;

  /// Account creation timestamp
  final DateTime createdAt;

  /// Last update timestamp
  final DateTime updatedAt;

  const UserProfile({
    required this.uid,
    required this.displayName,
    this.photoUrl,
    this.email,
    this.currentCrewId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserProfile(
      uid: doc.id,
      displayName: data['displayName'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      email: data['email'] as String?,
      currentCrewId: data['currentCrewId'] as String?,
      createdAt: timestampToDateTime(data['createdAt'] as Timestamp?),
      updatedAt: timestampToDateTime(data['updatedAt'] as Timestamp?),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (email != null) 'email': email,
      if (currentCrewId != null) 'currentCrewId': currentCrewId,
      'createdAt': dateTimeToTimestamp(createdAt),
      'updatedAt': serverTimestamp,
    };
  }

  /// For creating a new user (uses server timestamp)
  Map<String, dynamic> toFirestoreCreate() {
    return {
      'displayName': displayName,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (email != null) 'email': email,
      if (currentCrewId != null) 'currentCrewId': currentCrewId,
      'createdAt': serverTimestamp,
      'updatedAt': serverTimestamp,
    };
  }

  UserProfile copyWith({
    String? uid,
    String? displayName,
    String? photoUrl,
    String? email,
    String? currentCrewId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      email: email ?? this.email,
      currentCrewId: currentCrewId ?? this.currentCrewId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'UserProfile(uid: $uid, displayName: $displayName)';
}
