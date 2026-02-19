import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../utils/image_utils.dart';

/// Upload error with categorized reason for user-facing messages.
class UploadException implements Exception {
  final String userMessage;
  final String debugMessage;
  UploadException(this.userMessage, this.debugMessage);

  @override
  String toString() => 'UploadException: $debugMessage';
}

class StorageRepository {
  final _storage = FirebaseStorage.instance;

  /// Single source of truth for profile image path.
  static String buildProfileImagePath(String uid) => 'users/$uid/profile.jpg';

  /// Classify Firebase Storage errors into user-friendly messages.
  Never _handleStorageError(Object error, String operation) {
    debugPrint('[Storage] $operation failed: $error');

    if (error is FirebaseException) {
      final msg = switch (error.code) {
        'unauthorized' || 'permission-denied' =>
          '업로드 실패 (권한 없음). 로그인 상태를 확인해주세요.',
        'canceled' =>
          '업로드가 취소되었습니다.',
        'retry-limit-exceeded' || 'unknown' =>
          '업로드 실패 (네트워크). 인터넷 연결을 확인해주세요.',
        'quota-exceeded' =>
          '저장 공간이 부족합니다. 관리자에게 문의해주세요.',
        'invalid-argument' =>
          '이미지 파일이 올바르지 않습니다.',
        _ =>
          '업로드 실패: ${error.message ?? error.code}',
      };
      throw UploadException(msg, '[$operation] FirebaseException(${error.code}): ${error.message}');
    }

    throw UploadException(
      '업로드 실패 (네트워크). 잠시 후 다시 시도해주세요.',
      '[$operation] $error',
    );
  }

  /// Upload profile photo
  /// Path: users/{uid}/profile.jpg
  /// Returns download URL on success, throws [UploadException] on failure.
  Future<String> uploadProfilePhoto(String uid, File imageFile) async {
    final compressed = await compressImage(imageFile);
    if (compressed == null) {
      throw UploadException(
        '이미지 처리에 실패했습니다. 다른 사진을 선택해주세요.',
        '[uploadProfilePhoto] compressImage returned null',
      );
    }

    try {
      final ref = _storage.ref().child(buildProfileImagePath(uid));

      await ref.putFile(
        compressed,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final url = await ref.getDownloadURL();
      debugPrint('[Storage] uploadProfilePhoto: success → $url');
      return url;
    } catch (e) {
      _handleStorageError(e, 'uploadProfilePhoto');
    }
  }

  /// Upload workout proof photo
  /// Path: crews/{crewId}/proofs/{uid}/{dateKey}.jpg
  /// Returns (url, path) on success, throws [UploadException] on failure.
  Future<({String url, String path})> uploadWorkoutPhoto(
    String crewId,
    String uid,
    String dateKey,
    File imageFile,
  ) async {
    final compressed = await compressImage(imageFile);
    if (compressed == null) {
      throw UploadException(
        '이미지 처리에 실패했습니다. 다른 사진을 선택해주세요.',
        '[uploadWorkoutPhoto] compressImage returned null',
      );
    }

    // Declare path outside try so it's included in the error log
    final path = 'crews/$crewId/proofs/$uid/$dateKey.jpg';
    try {
      final ref = _storage.ref().child(path);

      await ref.putFile(
        compressed,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final url = await ref.getDownloadURL();
      debugPrint('[Storage] uploadWorkoutPhoto: success → $url');
      return (url: url, path: path);
    } catch (e) {
      _handleStorageError(e, 'uploadWorkoutPhoto[path=$path]');
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

  /// Delete profile photo
  Future<void> deleteProfilePhoto(String uid) async {
    try {
      await _storage.ref().child(buildProfileImagePath(uid)).delete();
    } catch (_) {
      // Ignore if file doesn't exist
    }
  }
}
