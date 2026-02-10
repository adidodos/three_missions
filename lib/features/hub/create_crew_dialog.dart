import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/repositories/crew_repository.dart';
import 'hub_provider.dart';

class CreateCrewDialog extends ConsumerStatefulWidget {
  const CreateCrewDialog({super.key});

  @override
  ConsumerState<CreateCrewDialog> createState() => _CreateCrewDialogState();
}

class _CreateCrewDialogState extends ConsumerState<CreateCrewDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      final repo = ref.read(crewRepositoryProvider);
      await repo.createCrew(
        _nameController.text.trim(),
        user.uid,
        user.displayName ?? 'User',
        user.photoURL,
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } on CrewNameTakenException {
      if (mounted) {
        setState(() => _errorMessage = '이미 사용 중인 크루 이름입니다');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = '오류가 발생했습니다: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('크루 생성'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: '크루 이름',
                hintText: '예: 아침 러닝 크루',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '크루 이름을 입력하세요';
                }
                if (value.trim().length < 2) {
                  return '2자 이상 입력하세요';
                }
                return null;
              },
              onFieldSubmitted: (_) => _create(),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
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
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _create,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('생성'),
        ),
      ],
    );
  }
}
