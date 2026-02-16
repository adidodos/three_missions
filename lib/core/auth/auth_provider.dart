import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_repository.dart';
import '../repositories/user_repository.dart';
import '../models/user_profile.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).value;
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// Admin check cached in provider state.
/// Admin condition: /admins/{uid} document exists.
final isAdminProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;

  final firestore = ref.watch(firestoreProvider);
  final adminDoc = await firestore.collection('admins').doc(user.uid).get();
  return adminDoc.exists;
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

/// Ensures user profile exists in Firestore after login
final ensureUserProfileProvider = FutureProvider.autoDispose<void>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return;

  final repo = ref.read(userRepositoryProvider);
  final profile = UserProfile(
    uid: user.uid,
    displayName: user.displayName ?? 'User',
    email: user.email,
    photoUrl: user.photoURL,
    createdAt: DateTime.now(),
  );
  try {
    await repo.ensureUser(profile);
  } catch (_) {
    // Firestore rules may not be deployed yet; skip silently
  }
});
