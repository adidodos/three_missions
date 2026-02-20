import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/firestore_converters.dart';

/// User profile: /users/{uid}
class UserProfile {
  final String uid;
  final String displayName;
  final String? email;
  /// Custom-uploaded photo URL. Google's photoURL is NEVER stored here.
  /// Only populated after the user explicitly uploads a custom photo.
  final String? photoUrl;
  /// True only after the user uploads a custom profile photo.
  /// Defaults to false for new users; Google avatar is never used.
  final bool hasCustomPhoto;
  final DateTime createdAt;
  // 동네 정보
  final String? sido;       // 시/도
  final String? sigungu;    // 시/군/구
  final String? dong;       // 읍/면/동

  const UserProfile({
    required this.uid,
    required this.displayName,
    this.email,
    this.photoUrl,
    this.hasCustomPhoto = false,
    required this.createdAt,
    this.sido,
    this.sigungu,
    this.dong,
  });

  bool get hasLocation => sido != null && sigungu != null && dong != null;

  factory UserProfile.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserProfile(
      uid: doc.id,
      displayName: data['displayName'] as String? ?? '',
      email: data['email'] as String?,
      photoUrl: data['photoUrl'] as String?,
      hasCustomPhoto: data['hasCustomPhoto'] as bool? ?? false,
      createdAt: timestampToDateTime(data['createdAt'] as Timestamp?),
      sido: data['sido'] as String?,
      sigungu: data['sigungu'] as String?,
      dong: data['dong'] as String?,
    );
  }

  /// Used when creating a new user document.
  /// photoUrl is intentionally omitted – Google's URL is never written here.
  Map<String, dynamic> toFirestoreCreate() => {
    'displayName': displayName,
    if (email != null) 'email': email,
    'hasCustomPhoto': false,
    'createdAt': serverTimestamp,
  };

  /// Used for display-name / email updates only.
  /// photoUrl and hasCustomPhoto are managed separately via
  /// [UserRepository.updatePhotoUrl], which sets both atomically.
  Map<String, dynamic> toFirestoreUpdate() => {
    'displayName': displayName,
    if (email != null) 'email': email,
  };

  UserProfile copyWith({
    String? displayName,
    String? email,
    String? photoUrl,
    bool? hasCustomPhoto,
    String? sido,
    String? sigungu,
    String? dong,
  }) => UserProfile(
    uid: uid,
    displayName: displayName ?? this.displayName,
    email: email ?? this.email,
    photoUrl: photoUrl ?? this.photoUrl,
    hasCustomPhoto: hasCustomPhoto ?? this.hasCustomPhoto,
    createdAt: createdAt,
    sido: sido ?? this.sido,
    sigungu: sigungu ?? this.sigungu,
    dong: dong ?? this.dong,
  );
}
