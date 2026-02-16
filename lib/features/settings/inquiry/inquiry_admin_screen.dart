import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/models/inquiry.dart';
import '../../../core/repositories/inquiry_repository.dart';

final _allInquiriesProvider = StreamProvider<List<Inquiry>>((ref) {
  final repo = ref.watch(inquiryRepositoryProvider);
  return repo.watchAllInquiries();
});

class InquiryAdminScreen extends ConsumerWidget {
  const InquiryAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdminAsync = ref.watch(isAdminProvider);
    return isAdminAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('문의 관리')),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const _AdminAccessDeniedBody(),
      data: (isAdmin) {
        if (!isAdmin) {
          return const _AdminAccessDeniedBody();
        }
        return _InquiryAdminListBody();
      },
    );
  }
}

class _InquiryAdminListBody extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inquiriesAsync = ref.watch(_allInquiriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('문의 관리')),
      body: inquiriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (inquiries) {
          if (inquiries.isEmpty) {
            return const Center(child: Text('문의가 없습니다'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: inquiries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final inquiry = inquiries[index];
              return _AdminInquiryCard(inquiry: inquiry);
            },
          );
        },
      ),
    );
  }
}

class _AdminAccessDeniedBody extends StatefulWidget {
  const _AdminAccessDeniedBody();

  @override
  State<_AdminAccessDeniedBody> createState() => _AdminAccessDeniedBodyState();
}

class _AdminAccessDeniedBodyState extends State<_AdminAccessDeniedBody> {
  bool _navigated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_navigated) return;
    _navigated = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/settings');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('문의 관리')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 44),
            SizedBox(height: 8),
            Text('권한 없음'),
          ],
        ),
      ),
    );
  }
}

class _AdminInquiryCard extends ConsumerWidget {
  final Inquiry inquiry;
  const _AdminInquiryCard({required this.inquiry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('yyyy.MM.dd HH:mm');
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inquiry.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${inquiry.displayName} · ${dateFormat.format(inquiry.createdAt)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: inquiry.isAnswered
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    inquiry.isAnswered ? '답변완료' : '대기중',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: inquiry.isAnswered ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(inquiry.content, style: theme.textTheme.bodyMedium),

            if (inquiry.isAnswered) ...[
              const Divider(height: 24),
              Text(inquiry.answer!, style: theme.textTheme.bodyMedium),
            ],

            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _showAnswerDialog(context, ref),
                icon: Icon(
                  inquiry.isAnswered ? Icons.edit : Icons.reply,
                  size: 18,
                ),
                label: Text(inquiry.isAnswered ? '답변 수정' : '답변하기'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAnswerDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: inquiry.answer ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        var loading = false;
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: const Text('답변 작성'),
            content: TextField(
              controller: controller,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: '답변을 입력해주세요',
                alignLabelWithHint: true,
              ),
            ),
            actions: [
              TextButton(
                onPressed: loading ? null : () => Navigator.pop(ctx),
                child: const Text('취소'),
              ),
              FilledButton(
                onPressed: loading
                    ? null
                    : () async {
                        final text = controller.text.trim();
                        if (text.isEmpty) return;

                        setState(() => loading = true);
                        try {
                          final repo = ref.read(inquiryRepositoryProvider);
                          await repo.answerInquiry(inquiry.id, text);
                          if (ctx.mounted) Navigator.pop(ctx);
                        } catch (e) {
                          setState(() => loading = false);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text('답변 등록 실패: $e')),
                            );
                          }
                        }
                      },
                child: loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('등록'),
              ),
            ],
          ),
        );
      },
    );
  }
}
