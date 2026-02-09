import 'package:cloud_firestore/cloud_firestore.dart';

class Member {
  final String id;
  final String name;
  final String? uid;
  final bool isMe;
  final DateTime createdAt;

  Member({
    required this.id,
    required this.name,
    this.uid,
    this.isMe = false,
    required this.createdAt,
  });

  factory Member.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Member(
      id: doc.id,
      name: data['name'] ?? '',
      uid: data['uid'],
      isMe: data['isMe'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      if (uid != null) 'uid': uid,
      'isMe': isMe,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  Member copyWith({
    String? id,
    String? name,
    String? uid,
    bool? isMe,
    DateTime? createdAt,
  }) {
    return Member(
      id: id ?? this.id,
      name: name ?? this.name,
      uid: uid ?? this.uid,
      isMe: isMe ?? this.isMe,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
