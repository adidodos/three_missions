import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/log_provider.dart';
import '../../../members/presentation/providers/member_provider.dart';
import '../../../members/data/models/member.dart';
import '../../../exercise_types/presentation/providers/exercise_type_provider.dart';
import '../../../exercise_types/data/models/exercise_type.dart';
import '../../../../core/utils/date_utils.dart';

class AddLogScreen extends ConsumerStatefulWidget {
  const AddLogScreen({super.key});

  @override
  ConsumerState<AddLogScreen> createState() => _AddLogScreenState();
}

class _AddLogScreenState extends ConsumerState<AddLogScreen> {
  final _formKey = GlobalKey<FormState>();
  final _memoController = TextEditingController();
  final _durationController = TextEditingController();

  late DateTime _selectedDate;
  Member? _selectedMember;
  ExerciseType? _selectedExerciseType;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = AppDateUtils.today();
  }

  @override
  void dispose() {
    _memoController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMember == null || _selectedExerciseType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('멤버와 운동 종류를 선택해주세요')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final duration = _durationController.text.isNotEmpty
          ? int.tryParse(_durationController.text)
          : null;

      await ref.read(logNotifierProvider.notifier).addLog(
            memberId: _selectedMember!.id,
            memberName: _selectedMember!.name,
            exerciseTypeId: _selectedExerciseType!.id,
            exerciseTypeName: _selectedExerciseType!.name,
            date: AppDateUtils.toDateString(_selectedDate),
            memo: _memoController.text.trim().isEmpty
                ? null
                : _memoController.text.trim(),
            durationMinutes: duration,
          );

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
    final membersAsync = ref.watch(membersStreamProvider);
    final typesAsync = ref.watch(exerciseTypesStreamProvider);
    final myMemberAsync = ref.watch(myMemberProvider);

    // Set default member to "me" on first load
    if (_selectedMember == null) {
      myMemberAsync.whenData((myMember) {
        if (myMember != null && _selectedMember == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _selectedMember = myMember);
          });
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('운동 인증'),
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
            // Date
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('날짜'),
              subtitle: Text(AppDateUtils.toDisplayString(_selectedDate)),
              onTap: _selectDate,
            ),
            const Divider(),

            // Member
            membersAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('오류: $e'),
              data: (members) => DropdownButtonFormField<Member>(
                value: _selectedMember,
                decoration: const InputDecoration(
                  labelText: '멤버',
                  prefixIcon: Icon(Icons.person),
                ),
                items: members
                    .map((m) => DropdownMenuItem(
                          value: m,
                          child: Text(m.name),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedMember = value),
                validator: (value) => value == null ? '멤버를 선택해주세요' : null,
              ),
            ),
            const SizedBox(height: 16),

            // Exercise type
            typesAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('오류: $e'),
              data: (types) => DropdownButtonFormField<ExerciseType>(
                value: _selectedExerciseType,
                decoration: const InputDecoration(
                  labelText: '운동 종류',
                  prefixIcon: Icon(Icons.fitness_center),
                ),
                items: types
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.name),
                        ))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedExerciseType = value),
                validator: (value) => value == null ? '운동 종류를 선택해주세요' : null,
              ),
            ),
            const SizedBox(height: 16),

            // Duration
            TextFormField(
              controller: _durationController,
              decoration: const InputDecoration(
                labelText: '운동 시간 (분, 선택)',
                prefixIcon: Icon(Icons.timer),
                hintText: '예: 30',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Memo
            TextFormField(
              controller: _memoController,
              decoration: const InputDecoration(
                labelText: '메모 (선택)',
                prefixIcon: Icon(Icons.note),
                hintText: '오늘 운동 한줄 기록',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}
