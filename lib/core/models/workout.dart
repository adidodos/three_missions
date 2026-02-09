import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/firestore_converters.dart';
import '../utils/date_keys.dart';

/// Workout (운동 인증) model.
///
/// Firestore path: crews/{crewId}/workouts/{workoutId}
/// Document ID: "{uid}_{dateKey}" (e.g., "user123_2024-01-15")
///
/// This ID format enforces one workout per user per day.
class Workout {
  /// Workout document ID: "{uid}_{dateKey}"
  final String id;

  /// User's UID
  final String uid;

  /// Date key: "YYYY-MM-DD"
  final String dateKey;

  /// Week key: Monday's dateKey of this week (for weekly stats)
  final String weekKey;

  /// Workout type (e.g., "러닝", "헬스", "수영")
  final String type;

  /// Optional memo/note
  final String? memo;

  /// Photo URL (Firebase Storage download URL)
  final String? photoUrl;

  /// Photo path in Firebase Storage (for deletion)
  final String? photoPath;

  /// Creation timestamp
  final DateTime createdAt;

  /// Last update timestamp
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

  /// Creates a Workout with auto-generated id, dateKey, and weekKey.
  factory Workout.create({
    required String uid,
    required DateTime date,
    required String type,
    String? memo,
    String? photoUrl,
    String? photoPath,
  }) {
    final dateKey = toDateKey(date);
    final weekKey = toWeekKey(date);
    return Workout(
      id: toWorkoutId(uid, date),
      uid: uid,
      dateKey: dateKey,
      weekKey: weekKey,
      type: type,
      memo: memo,
      photoUrl: photoUrl,
      photoPath: photoPath,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
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

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'dateKey': dateKey,
      'weekKey': weekKey,
      'type': type,
      if (memo != null) 'memo': memo,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (photoPath != null) 'photoPath': photoPath,
      'createdAt': dateTimeToTimestamp(createdAt),
      'updatedAt': serverTimestamp,
    };
  }

  Map<String, dynamic> toFirestoreCreate() {
    return {
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
  }

  /// Returns the date as DateTime.
  DateTime get date => fromDateKey(dateKey);

  /// Returns the week's Monday as DateTime.
  DateTime get weekStart => fromDateKey(weekKey);

  Workout copyWith({
    String? id,
    String? uid,
    String? dateKey,
    String? weekKey,
    String? type,
    String? memo,
    String? photoUrl,
    String? photoPath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Workout(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      dateKey: dateKey ?? this.dateKey,
      weekKey: weekKey ?? this.weekKey,
      type: type ?? this.type,
      memo: memo ?? this.memo,
      photoUrl: photoUrl ?? this.photoUrl,
      photoPath: photoPath ?? this.photoPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'Workout(id: $id, type: $type, dateKey: $dateKey)';
}
