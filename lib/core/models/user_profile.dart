import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/firestore_converters.dart';

/// User profile: /users/{uid}
class UserProfile {
  final String uid;
  final String displayName;
  final String? email;
  final String? photoUrl;
  final DateTime createdAt;

  const UserProfile({
    required this.uid,
    required this.displayName,
    this.email,
    this.photoUrl,
    required this.createdAt,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserProfile(
      uid: doc.id,
      displayName: data['displayName'] as String? ?? '',
      email: data['email'] as String?,
      photoUrl: data['photoUrl'] as String?,
      createdAt: timestampToDateTime(data['createdAt'] as Timestamp?),
    );
  }

  Map<String, dynamic> toFirestoreCreate() => {
    'displayName': displayName,
    if (email != null) 'email': email,
    if (photoUrl != null) 'photoUrl': photoUrl,
    'createdAt': serverTimestamp,
  };

  Map<String, dynamic> toFirestoreUpdate() => {
    'displayName': displayName,
    if (email != null) 'email': email,
    if (photoUrl != null) 'photoUrl': photoUrl,
  };
}
