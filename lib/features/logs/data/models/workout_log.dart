import 'package:cloud_firestore/cloud_firestore.dart';

class WorkoutLog {
  final String id;
  final String memberId;
  final String memberName;
  final String exerciseTypeId;
  final String exerciseTypeName;
  final String date; // YYYY-MM-DD
  final String? memo;
  final int? durationMinutes;
  final String createdByUid;
  final DateTime createdAt;

  WorkoutLog({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.exerciseTypeId,
    required this.exerciseTypeName,
    required this.date,
    this.memo,
    this.durationMinutes,
    required this.createdByUid,
    required this.createdAt,
  });

  factory WorkoutLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WorkoutLog(
      id: doc.id,
      memberId: data['memberId'] ?? '',
      memberName: data['memberName'] ?? '',
      exerciseTypeId: data['exerciseTypeId'] ?? '',
      exerciseTypeName: data['exerciseTypeName'] ?? '',
      date: data['date'] ?? '',
      memo: data['memo'],
      durationMinutes: data['durationMinutes'],
      createdByUid: data['createdByUid'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'memberId': memberId,
      'memberName': memberName,
      'exerciseTypeId': exerciseTypeId,
      'exerciseTypeName': exerciseTypeName,
      'date': date,
      if (memo != null && memo!.isNotEmpty) 'memo': memo,
      if (durationMinutes != null) 'durationMinutes': durationMinutes,
      'createdByUid': createdByUid,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  WorkoutLog copyWith({
    String? id,
    String? memberId,
    String? memberName,
    String? exerciseTypeId,
    String? exerciseTypeName,
    String? date,
    String? memo,
    int? durationMinutes,
    String? createdByUid,
    DateTime? createdAt,
  }) {
    return WorkoutLog(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      memberName: memberName ?? this.memberName,
      exerciseTypeId: exerciseTypeId ?? this.exerciseTypeId,
      exerciseTypeName: exerciseTypeName ?? this.exerciseTypeName,
      date: date ?? this.date,
      memo: memo ?? this.memo,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      createdByUid: createdByUid ?? this.createdByUid,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
