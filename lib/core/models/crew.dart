import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/firestore_converters.dart';

/// Crew: /crews/{crewId}
class Crew {
  final String id;
  final String name;
  final String ownerUid;
  final DateTime createdAt;

  const Crew({
    required this.id,
    required this.name,
    required this.ownerUid,
    required this.createdAt,
  });

  factory Crew.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Crew(
      id: doc.id,
      name: data['name'] as String? ?? '',
      ownerUid: data['ownerUid'] as String? ?? '',
      createdAt: timestampToDateTime(data['createdAt'] as Timestamp?),
    );
  }

  Map<String, dynamic> toFirestoreCreate() => {
    'name': name,
    'ownerUid': ownerUid,
    'createdAt': serverTimestamp,
  };
}
