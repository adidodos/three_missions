import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/inquiry.dart';
import '../utils/firestore_converters.dart';

final inquiryRepositoryProvider = Provider<InquiryRepository>((ref) {
  return InquiryRepository();
});

class InquiryRepository {
  final FirebaseFirestore _firestore;

  InquiryRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _inquiriesRef =>
      _firestore.collection('inquiries');

  Future<void> submitInquiry(Inquiry inquiry) async {
    await _inquiriesRef.add(inquiry.toFirestoreCreate());
  }

  /// My inquiries (for regular users)
  Stream<List<Inquiry>> watchMyInquiries(String uid) {
    return _inquiriesRef
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Inquiry.fromFirestore(doc)).toList(),
        );
  }

  /// All inquiries (for admin/developer)
  Stream<List<Inquiry>> watchAllInquiries() {
    return _inquiriesRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Inquiry.fromFirestore(doc)).toList(),
        );
  }

  /// Answer an inquiry (admin only)
  Future<void> answerInquiry(String id, String answer) async {
    await _inquiriesRef.doc(id).update({
      'answer': answer,
      'answeredAt': serverTimestamp,
    });
  }

  /// Delete all inquiries for a user (for account deletion).
  Future<void> deleteUserInquiries(String uid) async {
    final snapshot = await _inquiriesRef.where('uid', isEqualTo: uid).get();

    if (snapshot.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
