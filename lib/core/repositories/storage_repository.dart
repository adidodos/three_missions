import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../utils/image_utils.dart';

class StorageRepository {
  final _storage = FirebaseStorage.instance;

  /// Upload profile photo
  /// Path: users/{uid}/profile.jpg
  Future<String?> uploadProfilePhoto(String uid, File imageFile) async {
    try {
      final compressed = await compressImage(imageFile);
      if (compressed == null) return null;

      final path = 'users/$uid/profile.jpg';
      final ref = _storage.ref().child(path);

      await ref.putFile(
        compressed,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  /// Upload workout photo
  /// Path: crews/{crewId}/workouts/{uid}/{dateKey}.jpg
  Future<({String url, String path})?> uploadWorkoutPhoto(
    String crewId,
    String uid,
    String dateKey,
    File imageFile,
  ) async {
    try {
      // Compress image
      final compressed = await compressImage(imageFile);
      if (compressed == null) return null;

      final path = 'crews/$crewId/workouts/$uid/$dateKey.jpg';
      final ref = _storage.ref().child(path);

      await ref.putFile(
        compressed,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final url = await ref.getDownloadURL();
      return (url: url, path: path);
    } catch (e) {
      return null;
    }
  }

  /// Delete workout photo
  Future<void> deleteWorkoutPhoto(String path) async {
    try {
      await _storage.ref().child(path).delete();
    } catch (_) {
      // Ignore if file doesn't exist
    }
  }
}
