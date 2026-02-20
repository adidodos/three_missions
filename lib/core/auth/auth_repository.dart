import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepository {
  final _auth = FirebaseAuth.instance;
  final _googleSignIn = GoogleSignIn.instance;
  bool _initialized = false;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await _googleSignIn.initialize();
      _initialized = true;
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      await _ensureInitialized();

      // Authenticate with Google
      final googleUser = await _googleSignIn.authenticate();
      // ignore: unnecessary_null_comparison
      if (googleUser == null) return null;

      // Get auth details
      final googleAuth = googleUser.authentication;

      // Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      return null;
    }
  }

  Future<void> updatePhotoURL(String url) async {
    await _auth.currentUser?.updatePhotoURL(url);
    await _auth.currentUser?.reload();
  }

  Future<void> updateDisplayName(String displayName) async {
    await _auth.currentUser?.updateDisplayName(displayName);
    await _auth.currentUser?.reload();
  }

  /// Re-authenticate with Google before sensitive operations (e.g. account deletion).
  /// Throws on failure/cancellation.
  Future<void> reauthenticateWithGoogle() async {
    await _ensureInitialized();

    final googleUser = await _googleSignIn.authenticate();
    // ignore: unnecessary_null_comparison
    if (googleUser == null) {
      throw Exception('재인증이 취소되었습니다.');
    }

    final googleAuth = googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    final user = _auth.currentUser;
    if (user == null) throw Exception('No user signed in');
    await user.reauthenticateWithCredential(credential);
  }

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user signed in');
    await user.delete();
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
