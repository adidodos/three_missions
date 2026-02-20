import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/models/wall_post.dart';
import '../wall_provider.dart';

/// 크루 검색 화면 하단에 노출되는 "내 동네 홍보 담벼락" 섹션
class WallSection extends ConsumerWidget {
  const WallSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(wallFilterProvider);
    final postsAsync = ref.watch(wallPostsProvider);
    final profile = ref.watch(userProfileProvider).value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 헤더 ──────────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: Row(
            children: [
              const Icon(Icons.campaign_outlined, size: 20),
              const SizedBox(width: 6),
              Text(
                '동네 크루 홍보 담벼락',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              // 동네 미설정 시 설정 유도 버튼
              if (!( profile?.hasLocation ?? false))
                TextButton.icon(
                  onPressed: () => context.push('/settings/neighborhood'),
                  icon: const Icon(Icons.location_on_outlined, size: 16),
                  label: const Text('동네 설정'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
        ),

        // ── 필터 탭 ──────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: _FilterChips(
            current: filter,
            profile: profile,
            onChanged: (f) =>
                ref.read(wallFilterProvider.notifier).set(f),
          ),
        ),

        // ── 글 목록 ──────────────────────────────────────────────────────────
        postsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text('오류: $e'),
          ),
          data: (posts) {
            if (posts.isEmpty) return _EmptyState(filter: filter, profile: profile);
            return ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: posts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _WallPostCard(post: posts[i]),
            );
          },
        ),

        const SizedBox(height: 24),
      ],
    );
  }
}

// ── 필터 칩 ───────────────────────────────────────────────────────────────────

class _FilterChips extends StatelessWidget {
  final WallFilter current;
  final dynamic profile;
  final ValueChanged<WallFilter> onChanged;

  const _FilterChips({
    required this.current,
    required this.profile,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasDong = profile?.dong != null;
    final hasSigungu = profile?.sigungu != null;

    return Wrap(
      spacing: 8,
      children: [
        _Chip(
          label: hasDong ? '${profile!.dong}' : '내 동네',
          selected: current == WallFilter.dong,
          onTap: () => onChanged(WallFilter.dong),
        ),
        _Chip(
          label: hasSigungu ? '${profile!.sigungu}' : '내 구',
          selected: current == WallFilter.sigungu,
          onTap: () => onChanged(WallFilter.sigungu),
        ),
        _Chip(
          label: '전체',
          selected: current == WallFilter.all,
          onTap: () => onChanged(WallFilter.all),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: cs.primaryContainer,
      checkmarkColor: cs.primary,
    );
  }
}

// ── 홍보글 카드 ──────────────────────────────────────────────────────────────

class _WallPostCard extends StatelessWidget {
  final WallPost post;
  const _WallPostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 크루명 + 위치
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: cs.primaryContainer,
                    child: Icon(Icons.group,
                        size: 16, color: cs.onPrimaryContainer),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.crewName,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${post.sigungu} ${post.dong}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: cs.outline),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // 제목
              Text(
                post.title,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // 내용 미리보기
              Text(
                post.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _PostDetailSheet(post: post),
    );
  }
}

// ── 상세 시트 ──────────────────────────────────────────────────────────────────

class _PostDetailSheet extends StatelessWidget {
  final WallPost post;
  const _PostDetailSheet({required this.post});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      minChildSize: 0.35,
      expand: false,
      builder: (ctx, ctrl) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: ListView(
            controller: ctrl,
            children: [
              // 드래그 핸들
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // 크루 명 + 지역
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(Icons.group,
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimaryContainer),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.crewName,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      Text(
                        '${post.sido} ${post.sigungu} ${post.dong}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color:
                                  Theme.of(context).colorScheme.outline,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(post.title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Text(post.content,
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/crew/${post.crewId}');
                },
                icon: const Icon(Icons.login),
                label: const Text('크루 보러가기'),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── 빈 상태 ──────────────────────────────────────────────────────────────────

class _EmptyState extends ConsumerWidget {
  final WallFilter filter;
  final dynamic profile;

  const _EmptyState({required this.filter, required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String msg;
    String sub;

    switch (filter) {
      case WallFilter.dong:
        final dong = profile?.dong;
        msg = dong != null ? '$dong 홍보 크루가 없어요' : '동네를 설정해주세요';
        sub = dong != null
            ? '이 동네에서 활동 중인 크루가 홍보글을 작성하면 여기 표시됩니다.'
            : '설정 후 내 동네 크루를 확인할 수 있습니다.';
      case WallFilter.sigungu:
        final sg = profile?.sigungu;
        msg = sg != null ? '$sg 홍보 크루가 없어요' : '동네를 설정해주세요';
        sub = '이 지역에서 활동 중인 크루가 없습니다.';
      case WallFilter.all:
        msg = '아직 홍보 중인 크루가 없어요';
        sub = '크루장은 크루 홈 → 관리에서 홍보글을 작성할 수 있습니다.';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        children: [
          Icon(Icons.campaign_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.outlineVariant),
          const SizedBox(height: 12),
          Text(msg,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(sub,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  )),
          if (filter == WallFilter.dong && profile?.dong == null) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => context.push('/settings/neighborhood'),
              icon: const Icon(Icons.location_on_outlined),
              label: const Text('동네 설정하러 가기'),
            ),
          ],
        ],
      ),
    );
  }
}
