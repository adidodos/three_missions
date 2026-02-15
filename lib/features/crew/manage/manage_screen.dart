import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/member.dart';
import '../../../core/repositories/crew_repository.dart';
import '../../../core/router/router.dart';
import '../../hub/hub_provider.dart';
import 'widgets/pending_requests_tab.dart';
import 'widgets/members_tab.dart';
import 'manage_provider.dart';

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
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _showDeleteConfirmation(context, ref),
            ),
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
    );
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
