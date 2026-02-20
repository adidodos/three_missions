import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/repositories/inquiry_repository.dart';
import '../../core/repositories/join_request_repository.dart';
import '../../core/repositories/storage_repository.dart';
import '../../core/repositories/workout_repository.dart';
import '../../core/router/router.dart';

class DeleteAccountDialog extends ConsumerStatefulWidget {
  final User user;
  const DeleteAccountDialog({super.key, required this.user});

  @override
  ConsumerState<DeleteAccountDialog> createState() =>
      _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends ConsumerState<DeleteAccountDialog> {
  bool _loading = false;
  String? _error;
  String? _progressText;

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;

    return AlertDialog(
      title: const Text('회원 탈퇴'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('계정을 삭제하면 다음 데이터가 영구적으로 삭제됩니다:'),
          const SizedBox(height: 12),
          const Text('  • 프로필 정보'),
          const Text('  • 모든 크루 멤버십'),
          const Text('  • 모든 운동 인증 기록 및 사진'),
          const Text('  • 가입 신청 내역'),
          const Text('  • 문의 내역'),
          const SizedBox(height: 12),
          Text(
            '이 작업은 되돌릴 수 없습니다.',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: errorColor),
          ),
          if (_progressText != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_progressText!,
                      style: const TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!,
                style: TextStyle(color: errorColor, fontSize: 13)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: _loading ? null : _confirmDelete,
          style: FilledButton.styleFrom(backgroundColor: errorColor),
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('탈퇴하기'),
        ),
      ],
    );
  }

  Future<void> _confirmDelete() async {
    // Second confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('정말 탈퇴하시겠습니까?'),
        content: const Text('모든 데이터가 영구적으로 삭제됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('삭제',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _loading = true;
      _error = null;
      _progressText = null;
    });

    try {
      final uid = widget.user.uid;
      final authRepo = ref.read(authRepositoryProvider);
      final memberRepo = ref.read(memberRepositoryProvider);
      final userRepo = ref.read(userRepositoryProvider);
      final storageRepo = StorageRepository();
      final workoutRepo = WorkoutRepository();
      final joinRequestRepo = JoinRequestRepository();
      final inquiryRepo = InquiryRepository();

      // 1. Check crew ownership
      _setProgress('크루 소유 여부 확인 중...');
      final ownedCrews = await memberRepo.getOwnedCrewIds(uid);
      if (ownedCrews.isNotEmpty) {
        setState(() {
          _error = '소유한 크루가 있어 탈퇴할 수 없습니다.\n먼저 크루를 삭제하거나 소유권을 이전하세요.';
          _loading = false;
          _progressText = null;
        });
        return;
      }

      // 2. Re-authenticate with Google
      _setProgress('계정 확인 중...');
      try {
        await authRepo.reauthenticateWithGoogle();
      } catch (e) {
        setState(() {
          _error = '계정 확인이 필요합니다. 다시 시도해주세요.';
          _loading = false;
          _progressText = null;
        });
        return;
      }

      // 3. Get all crew IDs the user is a member of
      _setProgress('크루 정보 조회 중...');
      final memberDocs = await memberRepo.getUserMemberDocs(uid);
      final crewIds = memberDocs
          .map((doc) => doc.reference.parent.parent?.id)
          .whereType<String>()
          .toList();

      // 4. Delete workouts + photos from each crew
      _setProgress('운동 기록 삭제 중...');
      for (final crewId in crewIds) {
        final photoPaths =
            await workoutRepo.removeUserWorkoutsFromCrew(crewId, uid);
        for (final path in photoPaths) {
          await storageRepo.deleteWorkoutPhoto(path);
        }
      }

      // 5. Delete join requests
      _setProgress('가입 신청 내역 삭제 중...');
      await joinRequestRepo.removeUserRequestsFromAllCrews(uid);

      // 6. Delete inquiries
      _setProgress('문의 내역 삭제 중...');
      await inquiryRepo.deleteUserInquiries(uid);

      // 7. Remove member docs from all crews
      _setProgress('크루 멤버십 정리 중...');
      await memberRepo.removeUserFromAllCrews(uid);

      // 8. Delete profile photo
      _setProgress('프로필 사진 삭제 중...');
      await storageRepo.deleteProfilePhoto(uid);

      // 9. Delete user document
      _setProgress('계정 정보 삭제 중...');
      await userRepo.deleteUser(uid);

      // 10. Delete Firebase Auth account
      _setProgress('계정 삭제 완료 중...');

      // Close dialog BEFORE deleting auth account.
      // deleteAccount() triggers authStateChanges → GoRouter redirects to /login.
      // If the dialog is still open, its context becomes invalid → black screen.
      if (mounted) Navigator.pop(context);

      await authRepo.deleteAccount();

      // Only sign out of Google (clear cached Google session).
      // Firebase auth user is already deleted, so _auth.signOut() is unnecessary.
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '계정 삭제 중 오류가 발생했습니다:\n$e';
          _loading = false;
          _progressText = null;
        });
      }
    }
  }

  void _setProgress(String text) {
    if (mounted) {
      setState(() => _progressText = text);
    }
  }
}
