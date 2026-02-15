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

  Future<void> createUser(UserProfile user) async {
    await _usersRef.doc(user.uid).set(user.toFirestoreCreate());
  }

  Future<void> updateUser(UserProfile user) async {
    await _usersRef.doc(user.uid).update(user.toFirestoreUpdate());
  }

  Future<void> updatePhotoUrl(String uid, String photoUrl) async {
    await _usersRef.doc(uid).update({'photoUrl': photoUrl});
  }

  Future<void> ensureUser(UserProfile user) async {
    final doc = await _usersRef.doc(user.uid).get();
    if (!doc.exists) {
      await createUser(user);
    } else {
      await updateUser(user);
    }
  }
}
