import 'package:cloud_firestore/cloud_firestore.dart';

class Crew {
  final String id;
  final String name;
  final String ownerUid;
  final DateTime createdAt;

  Crew({
    required this.id,
    required this.name,
    required this.ownerUid,
    required this.createdAt,
  });

  factory Crew.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Crew(
      id: doc.id,
      name: data['name'] ?? '',
      ownerUid: data['ownerUid'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'ownerUid': ownerUid,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
