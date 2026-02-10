import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/repositories/storage_repository.dart';
import '../../../core/models/workout.dart';
import '../../../core/utils/date_keys.dart';
import 'crew_home_provider.dart';

final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  return StorageRepository();
});

class WorkoutFormScreen extends ConsumerStatefulWidget {
  final String crewId;

  const WorkoutFormScreen({super.key, required this.crewId});

  @override
  ConsumerState<WorkoutFormScreen> createState() => _WorkoutFormScreenState();
}

class _WorkoutFormScreenState extends ConsumerState<WorkoutFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _typeController = TextEditingController();
  final _memoController = TextEditingController();

  File? _imageFile;
  String? _existingPhotoUrl;
  bool _isLoading = false;
  bool _isEdit = false;

  final _workoutTypes = ['러닝', '헬스', '수영', '자전거', '등산', '요가', '홈트', '기타'];

  @override
  void initState() {
    super.initState();
    _loadExistingWorkout();
  }

  Future<void> _loadExistingWorkout() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final repo = ref.read(workoutRepositoryProvider);
    final workout = await repo.getTodayWorkout(widget.crewId, user.uid);

    if (workout != null && mounted) {
      setState(() {
        _isEdit = true;
        _typeController.text = workout.type;
        _memoController.text = workout.memo ?? '';
        _existingPhotoUrl = workout.photoUrl;
      });
    }
  }

  @override
  void dispose() {
    _typeController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Photo is required for new workout
    if (!_isEdit && _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사진을 선택해주세요')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      String? photoUrl = _existingPhotoUrl;
      String? photoPath;

      // Upload new photo if selected
      if (_imageFile != null) {
        final storageRepo = ref.read(storageRepositoryProvider);
        final result = await storageRepo.uploadWorkoutPhoto(
          widget.crewId,
          user.uid,
          todayKey(),
          _imageFile!,
        );

        if (result == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('사진 업로드에 실패했습니다')),
            );
          }
          return;
        }

        photoUrl = result.url;
        photoPath = result.path;
      }

      final workoutRepo = ref.read(workoutRepositoryProvider);
      final workout = Workout.create(
        uid: user.uid,
        date: today(),
        type: _typeController.text.trim(),
        memo: _memoController.text.trim().isEmpty
            ? null
            : _memoController.text.trim(),
        photoUrl: photoUrl,
        photoPath: photoPath,
      );

      if (_isEdit) {
        await workoutRepo.updateWorkout(widget.crewId, workout);
      } else {
        await workoutRepo.createWorkout(widget.crewId, workout);
      }

      if (mounted) {
        context.pop();
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? '인증 수정' : '오늘 인증하기'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('저장'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Photo section
            Text(
              '인증 사진 ${_isEdit ? '' : '(필수)'}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildPhotoSection(),
            const SizedBox(height: 24),

            // Workout type
            Text(
              '운동 종류',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _workoutTypes.map((type) {
                final isSelected = _typeController.text == type;
                return ChoiceChip(
                  label: Text(type),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _typeController.text = type;
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _typeController,
              decoration: const InputDecoration(
                hintText: '직접 입력',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '운동 종류를 선택하거나 입력하세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Memo
            Text(
              '메모 (선택)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _memoController,
              decoration: const InputDecoration(
                hintText: '오늘 운동 한줄 기록',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    if (_imageFile != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              _imageFile!,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton.filled(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => _imageFile = null),
            ),
          ),
        ],
      );
    }

    if (_existingPhotoUrl != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: _existingPhotoUrl!,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                height: 200,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.edit),
              label: const Text('변경'),
            ),
          ),
        ],
      );
    }

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_a_photo,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _takePhoto,
                icon: const Icon(Icons.camera_alt),
                label: const Text('촬영'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo_library),
                label: const Text('갤러리'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
