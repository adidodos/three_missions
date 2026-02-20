import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/wall_post.dart';

class WallPostRepository {
  final FirebaseFirestore _firestore;

  WallPostRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _ref =>
      _firestore.collection('wall_posts');

  /// 특정 크루의 홍보글 (없으면 null)
  Future<WallPost?> getPost(String crewId) async {
    final doc = await _ref.doc(crewId).get();
    if (!doc.exists) return null;
    return WallPost.fromFirestore(doc);
  }

  /// 동 필터 — 최신순
  Stream<List<WallPost>> watchByDong(String dong) {
    return _ref
        .where('dong', isEqualTo: dong)
        .orderBy('updatedAt', descending: true)
        .limit(30)
        .snapshots()
        .map((s) => s.docs.map(WallPost.fromFirestore).toList());
  }

  /// 구 필터 — 최신순
  Stream<List<WallPost>> watchBySigungu(String sigungu) {
    return _ref
        .where('sigungu', isEqualTo: sigungu)
        .orderBy('updatedAt', descending: true)
        .limit(30)
        .snapshots()
        .map((s) => s.docs.map(WallPost.fromFirestore).toList());
  }

  /// 전체 필터 — 최신순
  Stream<List<WallPost>> watchAll() {
    return _ref
        .orderBy('updatedAt', descending: true)
        .limit(50)
        .snapshots()
        .map((s) => s.docs.map(WallPost.fromFirestore).toList());
  }

  /// 홍보글 생성 (crewId = 문서 ID)
  Future<void> createPost(WallPost post) async {
    await _ref.doc(post.crewId).set(post.toFirestoreCreate());
  }

  /// 홍보글 수정 (제목/내용/위치)
  Future<void> updatePost(WallPost post) async {
    await _ref.doc(post.crewId).update(post.toFirestoreUpdate());
  }

  /// 홍보글 삭제
  Future<void> deletePost(String crewId) async {
    await _ref.doc(crewId).delete();
  }
}
