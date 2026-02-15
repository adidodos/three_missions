import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/firestore_converters.dart';
import 'crew_settings.dart';

/// Crew: /crews/{crewId}
class Crew {
  final String id;
  final String name;
  final String ownerUid;
  final DateTime createdAt;
  final CrewSettings? settings;

  const Crew({
    required this.id,
    required this.name,
    required this.ownerUid,
    required this.createdAt,
    this.settings,
  });

  bool get isSetupComplete => settings != null;

  factory Crew.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final settingsData = data['settings'] as Map<String, dynamic>?;
    return Crew(
      id: doc.id,
      name: data['name'] as String? ?? '',
      ownerUid: data['ownerUid'] as String? ?? '',
      createdAt: timestampToDateTime(data['createdAt'] as Timestamp?),
      settings: settingsData != null ? CrewSettings.fromMap(settingsData) : null,
    );
  }

  Map<String, dynamic> toFirestoreCreate() => {
    'name': name,
    'ownerUid': ownerUid,
    'createdAt': serverTimestamp,
  };
}
