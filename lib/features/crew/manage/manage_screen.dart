import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/member.dart';
import '../../../core/repositories/crew_repository.dart';
import '../../../core/repositories/member_repository.dart';
import '../../../core/router/router.dart';
import '../../hub/hub_provider.dart';
import 'widgets/pending_requests_tab.dart';
import 'widgets/members_tab.dart';
import 'manage_provider.dart';
import '../home/crew_home_provider.dart';
import '../../wall/wall_post_form_screen.dart';
import '../../wall/wall_provider.dart';

class ManageScreen extends ConsumerStatefulWidget {
  final String crewId;

  const ManageScreen({super.key, required this.crewId});

  @override
  ConsumerState<ManageScreen> createState() => _ManageScreenState();
}

class _ManageScreenState extends ConsumerState<ManageScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pendingAsync = ref.watch(managePendingRequestsProvider(widget.crewId));
    final pendingCount = pendingAsync.value?.length ?? 0;

    final currentMember = ref.watch(crewMembershipProvider(widget.crewId)).value;
    final isOwner = currentMember?.role == MemberRole.owner;

    return Scaffold(
      appBar: AppBar(
        title: const Text('크루 관리'),
        actions: [
          if (isOwner) ...[
            // 홍보글 작성/수정
            IconButton(
              icon: const Icon(Icons.campaign_outlined),
              tooltip: '홍보글 관리',
              onPressed: () => _openWallPostForm(context, ref),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _showDeleteConfirmation(context, ref),
            ),
          ],
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('가입 신청'),
                  if (pendingCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$pendingCount',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onError,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: '멤버 관리'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          PendingRequestsTab(crewId: widget.crewId),
          MembersTab(crewId: widget.crewId),
        ],
      ),
      floatingActionButton: kDebugMode
          ? FloatingActionButton(
              onPressed: () => _addTestMember(context, ref),
              child: const Icon(Icons.person_add),
            )
          : null,
    );
  }

  Future<void> _openWallPostForm(BuildContext context, WidgetRef ref) async {
    final crewAsync = ref.read(crewDetailProvider(widget.crewId));
    final crewName = crewAsync.value?.name ?? '';
    final existing = await ref.read(crewWallPostProvider(widget.crewId).future);

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WallPostFormScreen(
          crewId: widget.crewId,
          crewName: crewName,
          existing: existing,
        ),
      ),
    );
  }

  Future<void> _addTestMember(BuildContext context, WidgetRef ref) async {
    final random = Random();
    final names = ['김철수', '이영희', '박민수', '정수진', '최준호', '한지민', '오세훈', '윤서연'];
    final name = names[random.nextInt(names.length)];
    final fakeUid = 'test_${DateTime.now().millisecondsSinceEpoch}';

    final member = Member(
      uid: fakeUid,
      displayName: name,
      role: MemberRole.member,
      joinedAt: DateTime.now(),
    );

    try {
      await MemberRepository().addMember(widget.crewId, member);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('테스트 멤버 "$name" 추가 완료')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e')),
        );
      }
    }
  }

  Future<void> _showDeleteConfirmation(BuildContext context, WidgetRef ref) async {
    final router = GoRouter.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('크루 삭제'),
        content: const Text(
          '크루를 삭제하면 모든 멤버가 방출되며,\n이 작업은 되돌릴 수 없습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await CrewRepository().deleteCrew(widget.crewId);
    ref.invalidate(myCrewsProvider);
    if (mounted) {
      router.go('/hub');
    }
  }
}
