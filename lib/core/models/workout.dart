import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/firestore_converters.dart';
import '../utils/date_keys.dart';

/// Workout: /crews/{crewId}/workouts/{uid}_{dateKey}
class Workout {
  final String id; // {uid}_{dateKey}
  final String uid;
  final String dateKey;
  final String weekKey;
  final String type;
  final String? memo;
  final String? photoUrl;
  final String? photoPath;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Workout({
    required this.id,
    required this.uid,
    required this.dateKey,
    required this.weekKey,
    required this.type,
    this.memo,
    this.photoUrl,
    this.photoPath,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Workout.create({
    required String uid,
    required DateTime date,
    required String type,
    String? memo,
    String? photoUrl,
    String? photoPath,
  }) {
    final now = DateTime.now();
    return Workout(
      id: toWorkoutId(uid, date),
      uid: uid,
      dateKey: toDateKey(date),
      weekKey: toWeekKey(date),
      type: type,
      memo: memo,
      photoUrl: photoUrl,
      photoPath: photoPath,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory Workout.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Workout(
      id: doc.id,
      uid: data['uid'] as String? ?? '',
      dateKey: data['dateKey'] as String? ?? '',
      weekKey: data['weekKey'] as String? ?? '',
      type: data['type'] as String? ?? '',
      memo: data['memo'] as String?,
      photoUrl: data['photoUrl'] as String?,
      photoPath: data['photoPath'] as String?,
      createdAt: timestampToDateTime(data['createdAt'] as Timestamp?),
      updatedAt: timestampToDateTime(data['updatedAt'] as Timestamp?),
    );
  }

  Map<String, dynamic> toFirestoreCreate() => {
    'uid': uid,
    'dateKey': dateKey,
    'weekKey': weekKey,
    'type': type,
    if (memo != null) 'memo': memo,
    if (photoUrl != null) 'photoUrl': photoUrl,
    if (photoPath != null) 'photoPath': photoPath,
    'createdAt': serverTimestamp,
    'updatedAt': serverTimestamp,
  };

  Map<String, dynamic> toFirestoreUpdate() => {
    'type': type,
    if (memo != null) 'memo': memo,
    if (photoUrl != null) 'photoUrl': photoUrl,
    if (photoPath != null) 'photoPath': photoPath,
    'updatedAt': serverTimestamp,
  };

  DateTime get date => fromDateKey(dateKey);

  Workout copyWith({
    String? type,
    String? memo,
    String? photoUrl,
    String? photoPath,
  }) => Workout(
    id: id,
    uid: uid,
    dateKey: dateKey,
    weekKey: weekKey,
    type: type ?? this.type,
    memo: memo ?? this.memo,
    photoUrl: photoUrl ?? this.photoUrl,
    photoPath: photoPath ?? this.photoPath,
    createdAt: createdAt,
    updatedAt: DateTime.now(),
  );
}
