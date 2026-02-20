import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/models/wall_post.dart';
import 'wall_provider.dart';

/// 크루 홍보글 작성/수정 화면 (크루장 전용)
class WallPostFormScreen extends ConsumerStatefulWidget {
  final String crewId;
  final String crewName;
  /// 수정 모드일 때 기존 글
  final WallPost? existing;

  const WallPostFormScreen({
    super.key,
    required this.crewId,
    required this.crewName,
    this.existing,
  });

  @override
  ConsumerState<WallPostFormScreen> createState() => _WallPostFormScreenState();
}

class _WallPostFormScreenState extends ConsumerState<WallPostFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;

  String? _sido;
  String? _sigungu;
  String? _dong;
  bool _saving = false;
  String? _errorMsg;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    _titleCtrl = TextEditingController(text: ex?.title ?? widget.crewName);
    _contentCtrl = TextEditingController(text: ex?.content ?? '');

    if (ex != null) {
      _sido = ex.sido;
      _sigungu = ex.sigungu;
      _dong = ex.dong;
    } else {
      // 작성자의 동네로 프리필
      final profile = ref.read(userProfileProvider).value;
      _sido = profile?.sido;
      _sigungu = profile?.sigungu;
      _dong = profile?.dong;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sidoAsync = ref.watch(sidoListProvider);
    final sigunguAsync = _sido != null
        ? ref.watch(sigunguListProvider(_sido!))
        : const AsyncValue<List<String>>.data([]);
    final dongAsync = (_sido != null && _sigungu != null)
        ? ref.watch(dongListProvider((_sido!, _sigungu!)))
        : const AsyncValue<List<String>>.data([]);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? '홍보글 수정' : '홍보글 작성'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('저장'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── 오류 배너 ──────────────────────────────────────────────────
            if (_errorMsg != null) ...[
              _ErrorBanner(
                message: _errorMsg!,
                onDismiss: () => setState(() => _errorMsg = null),
              ),
              const SizedBox(height: 12),
            ],

            // ── 제목 ────────────────────────────────────────────────────────
            Text('제목', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleCtrl,
              maxLength: 40,
              decoration: const InputDecoration(
                hintText: '홍보글 제목',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '제목을 입력하세요' : null,
            ),

            const SizedBox(height: 16),

            // ── 내용 ────────────────────────────────────────────────────────
            Text('홍보 내용', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            TextFormField(
              controller: _contentCtrl,
              maxLines: 6,
              maxLength: 500,
              decoration: const InputDecoration(
                hintText: '크루 소개, 활동 지역, 모집 조건 등을 자유롭게 작성하세요.',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '내용을 입력하세요' : null,
            ),

            const SizedBox(height: 16),

            // ── 위치 ────────────────────────────────────────────────────────
            Text('활동 지역', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            const Text(
              '담벼락에서 이 지역 필터로 노출됩니다.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),

            sidoAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('오류: $e'),
              data: (list) => _LocationDropdown(
                hint: '시/도',
                value: _sido,
                items: list,
                onChanged: (v) => setState(() {
                  _sido = v;
                  _sigungu = null;
                  _dong = null;
                }),
              ),
            ),
            const SizedBox(height: 10),
            sigunguAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('오류: $e'),
              data: (list) => _LocationDropdown(
                hint: '시/군/구',
                value: _sigungu,
                items: list,
                onChanged: _sido == null
                    ? null
                    : (v) => setState(() {
                          _sigungu = v;
                          _dong = null;
                        }),
              ),
            ),
            const SizedBox(height: 10),
            dongAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('오류: $e'),
              data: (list) => _LocationDropdown(
                hint: '읍/면/동',
                value: _dong,
                items: list,
                onChanged: _sigungu == null
                    ? null
                    : (v) => setState(() => _dong = v),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_sido == null || _sigungu == null || _dong == null) {
      setState(() => _errorMsg = '활동 지역을 모두 선택해주세요.');
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() {
      _saving = true;
      _errorMsg = null;
    });

    try {
      final repo = ref.read(wallPostRepositoryProvider);
      final post = WallPost(
        crewId: widget.crewId,
        crewName: widget.crewName,
        ownerUid: user.uid,
        title: _titleCtrl.text.trim(),
        content: _contentCtrl.text.trim(),
        sido: _sido!,
        sigungu: _sigungu!,
        dong: _dong!,
        createdAt: widget.existing?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (_isEdit) {
        await repo.updatePost(post);
      } else {
        await repo.createPost(post);
      }

      if (mounted) {
        ref.invalidate(crewWallPostProvider(widget.crewId));
        ref.invalidate(wallPostsProvider);
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEdit ? '홍보글이 수정되었습니다.' : '홍보글이 등록되었습니다.')),
        );
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        setState(() => _errorMsg = e.code == 'permission-denied'
            ? '크루장만 홍보글을 작성할 수 있습니다.'
            : '저장 실패 (${e.code})');
      }
    } catch (e) {
      if (mounted) setState(() => _errorMsg = '저장에 실패했습니다: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _LocationDropdown extends StatelessWidget {
  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?>? onChanged;

  const _LocationDropdown({
    required this.hint,
    required this.value,
    required this.items,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final resolved = (value != null && items.contains(value)) ? value : null;
    return DropdownButtonFormField<String>(
      key: ValueKey('$hint-$resolved'),
      initialValue: resolved,
      decoration: InputDecoration(
        hintText: hint,
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        enabled: onChanged != null && items.isNotEmpty,
      ),
      isExpanded: true,
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;
  const _ErrorBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: cs.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: TextStyle(color: cs.onErrorContainer, fontSize: 13)),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 16, color: cs.error),
            onPressed: onDismiss,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
