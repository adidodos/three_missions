import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class UserRepository {
  final _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');

  Future<UserProfile?> getUser(String uid) async {
    final doc = await _usersRef.doc(uid).get();
    if (!doc.exists) return null;
    return UserProfile.fromFirestore(doc);
  }

  Stream<UserProfile?> watchUser(String uid) {
    return _usersRef.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserProfile.fromFirestore(doc);
    });
  }

  Future<void> createUser(UserProfile user) async {
    await _usersRef.doc(user.uid).set(user.toFirestoreCreate());
  }

  Future<void> updateUser(UserProfile user) async {
    await _usersRef.doc(user.uid).update(user.toFirestoreUpdate());
  }

  /// Sets [photoUrl] and flips [hasCustomPhoto] to true atomically.
  /// Call this whenever the user explicitly uploads a custom profile photo.
  Future<void> updatePhotoUrl(String uid, String photoUrl) async {
    await _usersRef.doc(uid).update({
      'photoUrl': photoUrl,
      'hasCustomPhoto': true,
    });
  }

  Future<void> updateDisplayName(String uid, String displayName) async {
    await _usersRef.doc(uid).update({'displayName': displayName});
  }

  Future<void> deleteUser(String uid) async {
    await _usersRef.doc(uid).delete();
  }

  /// Ensures the user doc exists. Creates it if missing.
  /// Google's photoURL is NEVER written – the caller must always pass
  /// [user.photoUrl] == null. Custom photo upload is handled separately
  /// via [updatePhotoUrl].
  Future<void> ensureUser(UserProfile user) async {
    final doc = await _usersRef.doc(user.uid).get();
    if (!doc.exists) {
      await createUser(user);
    }
    // Never auto-sync Google's photoURL to existing users.
  }
}
