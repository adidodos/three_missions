import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/models/inquiry.dart';
import '../../../core/repositories/inquiry_repository.dart';
import 'inquiry_form_dialog.dart';

final _myInquiriesProvider = StreamProvider.family<List<Inquiry>, String>((
  ref,
  uid,
) {
  final repo = ref.watch(inquiryRepositoryProvider);
  return repo.watchMyInquiries(uid);
});

class InquiryScreen extends ConsumerWidget {
  const InquiryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () => const _InquiryScaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => _InquiryScaffold(
        body: _InquiryErrorState(
          message: '로그인 상태를 확인할 수 없습니다.\n$e',
          onRetry: () => ref.invalidate(authStateProvider),
        ),
      ),
      data: (user) {
        if (user == null) {
          return const _InquiryScaffold(
            body: _InquiryEmptyState(
              icon: Icons.lock_outline,
              title: '로그인이 필요합니다',
              subtitle: '다시 로그인한 뒤 문의를 이용해주세요.',
            ),
          );
        }

        final inquiriesAsync = ref.watch(_myInquiriesProvider(user.uid));
        return _InquiryScaffold(
          onCreate: () => _showInquiryForm(context, ref),
          body: inquiriesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _InquiryErrorState(
              message: '문의 내역을 불러오지 못했습니다.\n$e',
              onRetry: () => ref.invalidate(_myInquiriesProvider(user.uid)),
            ),
            data: (inquiries) {
              if (inquiries.isEmpty) {
                return const _InquiryEmptyState(
                  icon: Icons.question_answer_outlined,
                  title: '문의 내역이 없습니다',
                  subtitle: '우측 하단 버튼으로 문의를 등록해주세요.',
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: inquiries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final inquiry = inquiries[index];
                  return _InquiryCard(inquiry: inquiry);
                },
              );
            },
          ),
        );
      },
    );
  }

  void _showInquiryForm(BuildContext context, WidgetRef ref) {
    showDialog(context: context, builder: (_) => const InquiryFormDialog());
  }
}

class _InquiryScaffold extends StatelessWidget {
  final Widget body;
  final VoidCallback? onCreate;

  const _InquiryScaffold({required this.body, this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('문의하기')),
      floatingActionButton: onCreate == null
          ? null
          : FloatingActionButton(
              onPressed: onCreate,
              child: const Icon(Icons.edit),
            ),
      body: body,
    );
  }
}

class _InquiryErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _InquiryErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 44),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InquiryEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InquiryEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            Text(title),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _InquiryCard extends StatelessWidget {
  final Inquiry inquiry;
  const _InquiryCard({required this.inquiry});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy.MM.dd HH:mm');
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    inquiry.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _StatusChip(isAnswered: inquiry.isAnswered),
              ],
            ),
            const SizedBox(height: 8),
            Text(inquiry.content, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(
              dateFormat.format(inquiry.createdAt),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            if (inquiry.isAnswered) ...[
              const Divider(height: 24),
              Row(
                children: [
                  Icon(
                    Icons.support_agent,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '답변',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(inquiry.answer!, style: theme.textTheme.bodyMedium),
              if (inquiry.answeredAt != null) ...[
                const SizedBox(height: 4),
                Text(
                  dateFormat.format(inquiry.answeredAt!),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isAnswered;
  const _StatusChip({required this.isAnswered});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isAnswered
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isAnswered ? '답변완료' : '대기중',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isAnswered ? Colors.green : Colors.orange,
        ),
      ),
    );
  }
}
