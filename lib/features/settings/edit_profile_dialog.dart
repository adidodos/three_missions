import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/models/user_profile.dart';
import '../../core/repositories/storage_repository.dart';
import '../../core/router/router.dart';
import '../../core/widgets/shared_widgets.dart';
import '../crew/home/workout_form_screen.dart';

class EditProfileDialog extends ConsumerStatefulWidget {
  final User user;
  /// Firestore profile snapshot; used to read [hasCustomPhoto] and [photoUrl].
  final UserProfile? userProfile;

  const EditProfileDialog({
    super.key,
    required this.user,
    this.userProfile,
  });

  @override
  ConsumerState<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends ConsumerState<EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final FocusNode _nameFocusNode;
  bool _loading = false;
  String? _error;

  File? _pickedPhoto;
  String? _currentPhotoUrl;
  bool _hasCustomPhoto = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.user.displayName ?? '',
    );
    _nameFocusNode = FocusNode();
    // Use custom photo from Firestore profile – never use Google's photoURL
    _hasCustomPhoto = widget.userProfile?.hasCustomPhoto ?? false;
    _currentPhotoUrl = _hasCustomPhoto ? widget.userProfile?.photoUrl : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (picked != null && mounted) {
        setState(() {
          _pickedPhoto = File(picked.path);
          _error = null;
        });
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.code == 'photo_access_denied'
            ? '사진 접근 권한이 필요합니다.'
            : '갤러리를 열 수 없습니다.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('프로필 수정'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tappable profile avatar
            GestureDetector(
              onTap: _loading ? null : _pickPhoto,
              child: Stack(
                children: [
                  if (_pickedPhoto != null)
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: FileImage(_pickedPhoto!),
                    )
                  else
                    ProfileAvatar(
                      photoUrl: _currentPhotoUrl,
                      hasCustomPhoto: _hasCustomPhoto,
                      radius: 40,
                    ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        size: 16,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '사진을 탭하여 변경',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const ValueKey('edit_profile_name_field'),
              controller: _nameController,
              focusNode: _nameFocusNode,
              autofocus: true,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: '닉네임',
                hintText: '2자 이상 입력해주세요',
              ),
              validator: (value) {
                final trimmed = value?.trim() ?? '';
                if (trimmed.length < 2) return '2자 이상 입력해주세요';
                return null;
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('저장'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final name = _nameController.text.trim();
      final uid = widget.user.uid;

      // Upload photo if a new one was picked
      String? newPhotoUrl;
      if (_pickedPhoto != null) {
        final storageRepo = ref.read(storageRepositoryProvider);
        try {
          newPhotoUrl = await storageRepo.uploadProfilePhoto(uid, _pickedPhoto!);
        } on UploadException catch (e) {
          setState(() {
            _error = e.userMessage;
            _loading = false;
          });
          return;
        }
      }

      // Update display name
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.updateDisplayName(name);

      // Update photo URL in Firebase Auth if changed
      if (newPhotoUrl != null) {
        await authRepo.updatePhotoURL(newPhotoUrl);
      }

      final userRepo = ref.read(userRepositoryProvider);
      await userRepo.updateDisplayName(uid, name);

      // updatePhotoUrl also sets hasCustomPhoto: true atomically
      if (newPhotoUrl != null) {
        await userRepo.updatePhotoUrl(uid, newPhotoUrl);
      }

      final memberRepo = ref.read(memberRepositoryProvider);
      await memberRepo.updateDisplayNameInAllCrews(uid, name);

      // Sync custom photo to all crew member docs
      if (newPhotoUrl != null) {
        await memberRepo.updatePhotoUrlInAllCrews(uid, newPhotoUrl);
      }

      if (mounted) Navigator.pop(context, true);
    } on UploadException catch (e) {
      setState(() {
        _error = e.userMessage;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '프로필 수정 실패: $e';
        _loading = false;
      });
    }
  }
}
