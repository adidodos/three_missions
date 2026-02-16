import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/models/inquiry.dart';
import '../../../core/repositories/inquiry_repository.dart';

class InquiryFormDialog extends ConsumerStatefulWidget {
  const InquiryFormDialog({super.key});

  @override
  ConsumerState<InquiryFormDialog> createState() => _InquiryFormDialogState();
}

class _InquiryFormDialogState extends ConsumerState<InquiryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('문의 작성'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: '제목'),
              validator: (v) =>
                  (v?.trim().isEmpty ?? true) ? '제목을 입력해주세요' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: '내용',
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              validator: (v) =>
                  (v?.trim().isEmpty ?? true) ? '내용을 입력해주세요' : null,
            ),
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
              : const Text('등록'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('로그인이 필요합니다');

      final inquiry = Inquiry(
        id: '',
        uid: user.uid,
        email: user.email,
        displayName: user.displayName ?? 'User',
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        message: _contentController.text.trim(),
        status: 'PENDING',
        createdAt: DateTime.now(),
      );

      final repo = ref.read(inquiryRepositoryProvider);
      await repo.submitInquiry(inquiry);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('문의가 등록되었습니다')));
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('등록 실패: $e')));
      }
    }
  }
}
