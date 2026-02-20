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

/// Stable provider that only changes when the UID actually changes (sign in/out).
/// Unlike [currentUserProvider], this does NOT change when Firebase re-emits
/// the same user as a new object (e.g. on app resume from camera/gallery),
/// preventing unnecessary cascade re-evaluations on downstream providers.
final currentUidProvider = Provider<String?>((ref) {
  return ref.watch(currentUserProvider)?.uid;
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// Developer email that always has admin access.
const kDeveloperEmail = 'ddoddoyun1213@gmail.com';

/// Admin check cached in provider state.
/// Admin condition: /admins/{uid} document exists OR developer email match.
final isAdminProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;

  final firestore = ref.watch(firestoreProvider);
  final adminDoc = await firestore.collection('admins').doc(user.uid).get();

  if (adminDoc.exists) return true;

  // Developer email: auto-create admin document and return true
  if (user.email == kDeveloperEmail) {
    try {
      await firestore.collection('admins').doc(user.uid).set({
        'email': user.email,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // May fail if rules not yet deployed; still treat as admin in-app
    }
    return true;
  }

  return false;
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

/// Watches the current user's Firestore profile (photoUrl, displayName, etc.)
final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);
  final repo = ref.watch(userRepositoryProvider);
  return repo.watchUser(user.uid);
});

/// Ensures user profile exists in Firestore after login.
/// Google's photoURL is intentionally NOT stored; the default avatar
/// (역도 아이콘) is shown until the user explicitly uploads a custom photo.
final ensureUserProfileProvider = FutureProvider.autoDispose<void>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return;

  final repo = ref.read(userRepositoryProvider);
  final profile = UserProfile(
    uid: user.uid,
    displayName: user.displayName ?? 'User',
    email: user.email,
    photoUrl: null,        // Never write Google's photoURL to Firestore
    createdAt: DateTime.now(),
  );
  try {
    await repo.ensureUser(profile);
  } catch (_) {
    // Firestore rules may not be deployed yet; skip silently
  }
});
