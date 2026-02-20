import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../features/wall/wall_provider.dart';

class NeighborhoodScreen extends ConsumerStatefulWidget {
  const NeighborhoodScreen({super.key});

  @override
  ConsumerState<NeighborhoodScreen> createState() => _NeighborhoodScreenState();
}

class _NeighborhoodScreenState extends ConsumerState<NeighborhoodScreen> {
  String? _sido;
  String? _sigungu;
  String? _dong;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // 기존 동네 정보 프리필
    final profile = ref.read(userProfileProvider).value;
    _sido = profile?.sido;
    _sigungu = profile?.sigungu;
    _dong = profile?.dong;
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

    final canSave = _sido != null && _sigungu != null && _dong != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 동네 설정'),
        actions: [
          TextButton(
            onPressed: (canSave && !_saving) ? _save : null,
            child: _saving
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('저장'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            '크루 홍보 담벼락에서 내 동네 크루를 찾을 때 사용됩니다.',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 24),

          // ── 시/도 ────────────────────────────────────────────────────────
          _label(context, '시 / 도'),
          const SizedBox(height: 8),
          sidoAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('오류: $e'),
            data: (list) => _Picker(
              hint: '시/도 선택',
              value: _sido,
              items: list,
              onChanged: (v) => setState(() {
                _sido = v;
                _sigungu = null;
                _dong = null;
              }),
            ),
          ),

          const SizedBox(height: 20),

          // ── 시/군/구 ──────────────────────────────────────────────────────
          _label(context, '시 / 군 / 구'),
          const SizedBox(height: 8),
          sigunguAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('오류: $e'),
            data: (list) => _Picker(
              hint: '시/군/구 선택',
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

          const SizedBox(height: 20),

          // ── 읍/면/동 ──────────────────────────────────────────────────────
          _label(context, '읍 / 면 / 동'),
          const SizedBox(height: 8),
          dongAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('오류: $e'),
            data: (list) => _Picker(
              hint: '읍/면/동 선택',
              value: _dong,
              items: list,
              onChanged: _sigungu == null
                  ? null
                  : (v) => setState(() => _dong = v),
            ),
          ),

          if (canSave) ...[
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on,
                      color: Theme.of(context).colorScheme.primary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '$_sido $_sigungu $_dong',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _label(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.outline,
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Future<void> _save() async {
    final user = ref.read(currentUserProvider);
    if (user == null || _sido == null || _sigungu == null || _dong == null) return;

    setState(() => _saving = true);
    try {
      final repo = ref.read(userRepositoryProvider);
      await repo.updateLocation(
        user.uid,
        sido: _sido!,
        sigungu: _sigungu!,
        dong: _dong!,
      );
      ref.invalidate(userProfileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('동네가 $_sido $_sigungu $_dong 으로 설정되었습니다.')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ── 드롭다운 피커 ──────────────────────────────────────────────────────────────

class _Picker extends StatelessWidget {
  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?>? onChanged;

  const _Picker({
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
