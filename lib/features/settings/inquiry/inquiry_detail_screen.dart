import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/inquiry.dart';

class InquiryDetailScreen extends StatelessWidget {
  final Inquiry inquiry;

  const InquiryDetailScreen({super.key, required this.inquiry});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy.MM.dd HH:mm');
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('문의 상세')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status chip
            Row(
              children: [
                _StatusChip(isAnswered: inquiry.isAnswered),
                const Spacer(),
                Text(
                  dateFormat.format(inquiry.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              inquiry.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Content
            Text(
              inquiry.content,
              style: theme.textTheme.bodyMedium,
            ),

            // Answer section
            if (inquiry.isAnswered) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.support_agent,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '답변',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  inquiry.answer!,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              if (inquiry.answeredAt != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    dateFormat.format(inquiry.answeredAt!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isAnswered
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isAnswered ? '답변완료' : '대기중',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isAnswered ? Colors.green : Colors.orange,
        ),
      ),
    );
  }
}
