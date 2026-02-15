import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:three_missions/core/repositories/crew_repository.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late CrewRepository repo;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repo = CrewRepository(firestore: fakeFirestore);
  });

  group('deleteCrew', () {
    test('크루 문서와 모든 멤버 문서가 삭제된다', () async {
      // Arrange: 크루 + 멤버 3명 생성
      final crewRef = fakeFirestore.collection('crews').doc('crew1');
      await crewRef.set({
        'name': '테스트 크루',
        'ownerUid': 'owner1',
        'createdAt': DateTime.now(),
      });

      final membersRef = crewRef.collection('members');
      await membersRef.doc('owner1').set({
        'uid': 'owner1',
        'displayName': '오너',
        'role': 'OWNER',
        'status': 'ACTIVE',
        'joinedAt': DateTime.now(),
      });
      await membersRef.doc('member1').set({
        'uid': 'member1',
        'displayName': '멤버1',
        'role': 'MEMBER',
        'status': 'ACTIVE',
        'joinedAt': DateTime.now(),
      });
      await membersRef.doc('member2').set({
        'uid': 'member2',
        'displayName': '멤버2',
        'role': 'ADMIN',
        'status': 'ACTIVE',
        'joinedAt': DateTime.now(),
      });

      // 사전 확인
      final membersBefore = await membersRef.get();
      expect(membersBefore.docs.length, 3);

      // Act
      await repo.deleteCrew('crew1');

      // Assert: 크루 문서 삭제됨
      final crewDoc = await crewRef.get();
      expect(crewDoc.exists, false);

      // Assert: 모든 멤버 문서 삭제됨
      final membersAfter = await membersRef.get();
      expect(membersAfter.docs.length, 0);
    });

    test('멤버가 없는 크루도 정상 삭제된다', () async {
      // Arrange: 멤버 없는 크루
      final crewRef = fakeFirestore.collection('crews').doc('crew2');
      await crewRef.set({
        'name': '빈 크루',
        'ownerUid': 'owner1',
        'createdAt': DateTime.now(),
      });

      // Act
      await repo.deleteCrew('crew2');

      // Assert
      final crewDoc = await crewRef.get();
      expect(crewDoc.exists, false);
    });

    test('삭제 후 getMyCrews에서 조회되지 않는다', () async {
      // Arrange
      final crewRef = fakeFirestore.collection('crews').doc('crew3');
      await crewRef.set({
        'name': '삭제될 크루',
        'ownerUid': 'user1',
        'createdAt': DateTime.now(),
      });
      await crewRef.collection('members').doc('user1').set({
        'uid': 'user1',
        'displayName': '유저1',
        'role': 'OWNER',
        'status': 'ACTIVE',
        'joinedAt': DateTime.now(),
      });

      // 삭제 전: 조회 가능
      final crewsBefore = await repo.getMyCrews('user1');
      expect(crewsBefore.length, 1);

      // Act
      await repo.deleteCrew('crew3');

      // Assert: 더 이상 조회되지 않음
      final crewsAfter = await repo.getMyCrews('user1');
      expect(crewsAfter.length, 0);
    });
  });
}
