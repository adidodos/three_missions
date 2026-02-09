import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/log_provider.dart';
import '../../../members/presentation/providers/member_provider.dart';
import '../../../members/data/models/member.dart';
import '../../../exercise_types/presentation/providers/exercise_type_provider.dart';
import '../../../exercise_types/data/models/exercise_type.dart';
import '../../data/models/workout_log.dart';
import '../../../../core/utils/date_utils.dart';

class EditLogScreen extends ConsumerStatefulWidget {
  final String logId;

  const EditLogScreen({super.key, required this.logId});

  @override
  ConsumerState<EditLogScreen> createState() => _EditLogScreenState();
}

class _EditLogScreenState extends ConsumerState<EditLogScreen> {
  final _formKey = GlobalKey<FormState>();
  final _memoController = TextEditingController();
  final _durationController = TextEditingController();

  DateTime? _selectedDate;
  Member? _selectedMember;
  ExerciseType? _selectedExerciseType;
  WorkoutLog? _originalLog;
  bool _isLoading = false;
  bool _initialized = false;

  @override
  void dispose() {
    _memoController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _initializeFromLog(WorkoutLog log, List<Member> members, List<ExerciseType> types) {
    if (_initialized) return;
    _initialized = true;

    _originalLog = log;
    _selectedDate = AppDateUtils.fromDateString(log.date);
    _memoController.text = log.memo ?? '';
    _durationController.text = log.durationMinutes?.toString() ?? '';

    _selectedMember = members.where((m) => m.id == log.memberId).firstOrNull;
    _selectedExerciseType = types.where((t) => t.id == log.exerciseTypeId).firstOrNull;
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? AppDateUtils.today(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMember == null || _selectedExerciseType == null || _originalLog == null) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final duration = _durationController.text.isNotEmpty
          ? int.tryParse(_durationController.text)
          : null;

      final updatedLog = _originalLog!.copyWith(
        memberId: _selectedMember!.id,
        memberName: _selectedMember!.name,
        exerciseTypeId: _selectedExerciseType!.id,
        exerciseTypeName: _selectedExerciseType!.name,
        date: AppDateUtils.toDateString(_selectedDate!),
        memo: _memoController.text.trim().isEmpty ? null : _memoController.text.trim(),
        durationMinutes: duration,
      );

      await ref.read(logNotifierProvider.notifier).updateLog(updatedLog);

      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('삭제'),
        content: const Text('이 기록을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(logNotifierProvider.notifier).deleteLog(widget.logId);
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(logsStreamProvider);
    final membersAsync = ref.watch(membersStreamProvider);
    final typesAsync = ref.watch(exerciseTypesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('기록 수정'),
        actions: [
          IconButton(
            onPressed: _delete,
            icon: const Icon(Icons.delete),
          ),
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
      body: logsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (logs) {
          final log = logs.where((l) => l.id == widget.logId).firstOrNull;
          if (log == null) {
            return const Center(child: Text('기록을 찾을 수 없습니다'));
          }

          return membersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('오류: $e')),
            data: (members) => typesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('오류: $e')),
              data: (types) {
                _initializeFromLog(log, members, types);

                return Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_today),
                        title: const Text('날짜'),
                        subtitle: Text(_selectedDate != null
                            ? AppDateUtils.toDisplayString(_selectedDate!)
                            : ''),
                        onTap: _selectDate,
                      ),
                      const Divider(),

                      DropdownButtonFormField<Member>(
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
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<ExerciseType>(
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
                        onChanged: (value) => setState(() => _selectedExerciseType = value),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _durationController,
                        decoration: const InputDecoration(
                          labelText: '운동 시간 (분, 선택)',
                          prefixIcon: Icon(Icons.timer),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _memoController,
                        decoration: const InputDecoration(
                          labelText: '메모 (선택)',
                          prefixIcon: Icon(Icons.note),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
