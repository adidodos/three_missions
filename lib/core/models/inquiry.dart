import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/firestore_converters.dart';

/// Inquiry: /inquiries/{docId}
class Inquiry {
  final String id;
  final String uid;
  final String? email;
  final String displayName;
  final String title;
  final String content;
  final String message;
  final String? status;
  final String? answer;
  final DateTime createdAt;
  final DateTime? answeredAt;

  const Inquiry({
    required this.id,
    required this.uid,
    this.email,
    required this.displayName,
    required this.title,
    required this.content,
    required this.message,
    this.status,
    this.answer,
    required this.createdAt,
    this.answeredAt,
  });

  bool get isAnswered => answer != null;

  factory Inquiry.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final message =
        (data['message'] as String?) ?? (data['content'] as String?) ?? '';
    final title = (data['title'] as String?) ?? '문의';
    return Inquiry(
      id: doc.id,
      uid: data['uid'] as String,
      email: data['email'] as String?,
      displayName: data['displayName'] as String? ?? '',
      title: title,
      content: (data['content'] as String?) ?? message,
      message: message,
      status: data['status'] as String?,
      answer: data['answer'] as String?,
      createdAt: timestampToDateTime(data['createdAt'] as Timestamp?),
      answeredAt: timestampToDateTimeNullable(data['answeredAt'] as Timestamp?),
    );
  }

  Map<String, dynamic> toFirestoreCreate() => {
    'uid': uid,
    'email': email,
    'message': message,
    'status': status ?? 'PENDING',
    'displayName': displayName,
    'title': title,
    'content': content.isEmpty ? message : content,
    'createdAt': serverTimestamp,
  };
}
