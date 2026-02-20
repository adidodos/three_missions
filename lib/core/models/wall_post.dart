import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/firestore_converters.dart';

/// 크루 홍보 담벼락 글.
/// 컬렉션: /wall_posts/{crewId}  (crewId = 문서 ID → 크루당 1개)
class WallPost {
  final String crewId;
  final String crewName;
  final String ownerUid;
  final String title;
  final String content;
  final String sido;      // 시/도
  final String sigungu;   // 시/군/구
  final String dong;      // 읍/면/동
  final DateTime createdAt;
  final DateTime updatedAt;

  const WallPost({
    required this.crewId,
    required this.crewName,
    required this.ownerUid,
    required this.title,
    required this.content,
    required this.sido,
    required this.sigungu,
    required this.dong,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WallPost.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return WallPost(
      crewId: doc.id,
      crewName: d['crewName'] as String? ?? '',
      ownerUid: d['ownerUid'] as String? ?? '',
      title: d['title'] as String? ?? '',
      content: d['content'] as String? ?? '',
      sido: d['sido'] as String? ?? '',
      sigungu: d['sigungu'] as String? ?? '',
      dong: d['dong'] as String? ?? '',
      createdAt: timestampToDateTime(d['createdAt'] as Timestamp?),
      updatedAt: timestampToDateTime(d['updatedAt'] as Timestamp?),
    );
  }

  Map<String, dynamic> toFirestoreCreate() => {
    'crewId': crewId,
    'crewName': crewName,
    'ownerUid': ownerUid,
    'title': title,
    'content': content,
    'sido': sido,
    'sigungu': sigungu,
    'dong': dong,
    'createdAt': serverTimestamp,
    'updatedAt': serverTimestamp,
  };

  Map<String, dynamic> toFirestoreUpdate() => {
    'title': title,
    'content': content,
    'sido': sido,
    'sigungu': sigungu,
    'dong': dong,
    'updatedAt': serverTimestamp,
  };
}
