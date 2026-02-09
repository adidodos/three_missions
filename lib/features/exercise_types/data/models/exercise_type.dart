import 'package:cloud_firestore/cloud_firestore.dart';

class ExerciseType {
  final String id;
  final String name;
  final String? icon;
  final DateTime createdAt;

  ExerciseType({
    required this.id,
    required this.name,
    this.icon,
    required this.createdAt,
  });

  factory ExerciseType.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExerciseType(
      id: doc.id,
      name: data['name'] ?? '',
      icon: data['icon'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      if (icon != null) 'icon': icon,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  ExerciseType copyWith({
    String? id,
    String? name,
    String? icon,
    DateTime? createdAt,
  }) {
    return ExerciseType(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
