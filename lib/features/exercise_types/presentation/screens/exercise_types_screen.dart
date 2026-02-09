import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/exercise_type_provider.dart';
import '../../data/models/exercise_type.dart';

class ExerciseTypesScreen extends ConsumerStatefulWidget {
  const ExerciseTypesScreen({super.key});

  @override
  ConsumerState<ExerciseTypesScreen> createState() => _ExerciseTypesScreenState();
}

class _ExerciseTypesScreenState extends ConsumerState<ExerciseTypesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addType() async {
    final name = await _showNameDialog(title: '운동 종류 추가', initialValue: '');
    if (name != null && name.isNotEmpty) {
      await ref.read(exerciseTypeNotifierProvider.notifier).addExerciseType(name);
    }
  }

  Future<void> _editType(ExerciseType type) async {
    final name = await _showNameDialog(title: '운동 종류 수정', initialValue: type.name);
    if (name != null && name.isNotEmpty && name != type.name) {
      await ref.read(exerciseTypeNotifierProvider.notifier).updateExerciseType(type.id, name);
    }
  }

  Future<void> _deleteType(ExerciseType type) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('운동 종류 삭제'),
        content: Text('${type.name}을(를) 삭제하시겠습니까?'),
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
      await ref.read(exerciseTypeNotifierProvider.notifier).deleteExerciseType(type.id);
    }
  }

  Future<String?> _showNameDialog({required String title, required String initialValue}) {
    _nameController.text = initialValue;
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Form(
          key: _formKey,
          child: TextFormField(
            controller: _nameController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: '운동 종류',
              hintText: '운동 종류를 입력하세요',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '운동 종류를 입력해주세요';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                Navigator.pop(context, _nameController.text.trim());
              }
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final typesAsync = ref.watch(exerciseTypeNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('운동 종류 관리'),
      ),
      body: typesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (types) => types.isEmpty
            ? const Center(child: Text('운동 종류가 없습니다'))
            : ListView.builder(
                itemCount: types.length,
                itemBuilder: (context, index) {
                  final type = types[index];
                  return ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.fitness_center),
                    ),
                    title: Text(type.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editType(type),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteType(type),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addType,
        child: const Icon(Icons.add),
      ),
    );
  }
}
