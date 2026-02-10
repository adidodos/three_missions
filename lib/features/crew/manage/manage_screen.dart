import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('크루 관리'),
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
}
