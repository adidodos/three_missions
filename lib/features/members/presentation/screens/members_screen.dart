import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/member_provider.dart';
import '../../data/models/member.dart';

class MembersScreen extends ConsumerStatefulWidget {
  const MembersScreen({super.key});

  @override
  ConsumerState<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends ConsumerState<MembersScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addMember() async {
    final name = await _showNameDialog(title: '멤버 추가', initialValue: '');
    if (name != null && name.isNotEmpty) {
      await ref.read(memberNotifierProvider.notifier).addMember(name);
    }
  }

  Future<void> _editMember(Member member) async {
    final name = await _showNameDialog(title: '멤버 수정', initialValue: member.name);
    if (name != null && name.isNotEmpty && name != member.name) {
      await ref.read(memberNotifierProvider.notifier).updateMember(member.id, name);
    }
  }

  Future<void> _deleteMember(Member member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('멤버 삭제'),
        content: Text('${member.name}을(를) 삭제하시겠습니까?'),
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
      await ref.read(memberNotifierProvider.notifier).deleteMember(member.id);
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
              labelText: '이름',
              hintText: '멤버 이름을 입력하세요',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '이름을 입력해주세요';
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
    final membersAsync = ref.watch(memberNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('멤버 관리'),
      ),
      body: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (members) => members.isEmpty
            ? const Center(child: Text('멤버가 없습니다'))
            : ListView.builder(
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(member.name.isNotEmpty ? member.name[0] : '?'),
                    ),
                    title: Text(member.name),
                    subtitle: member.isMe ? const Text('나') : null,
                    trailing: member.isMe
                        ? IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _editMember(member),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _editMember(member),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _deleteMember(member),
                              ),
                            ],
                          ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMember,
        child: const Icon(Icons.add),
      ),
    );
  }
}
