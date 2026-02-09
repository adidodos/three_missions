# Firestore 문서 구조

## 컬렉션 구조

```
firestore/
├── users/{uid}                          # 사용자 프로필
├── crews/{crewId}                       # 크루 정보
│   ├── members/{uid}                    # 크루 멤버
│   ├── joinRequests/{uid}               # 가입 요청
│   └── workouts/{workoutId}             # 운동 인증 기록
```

---

## 1. users/{uid}

**경로**: `users/{uid}`
**문서 ID**: Firebase Auth UID

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| displayName | string | ✓ | 표시 이름 |
| photoUrl | string | | 프로필 사진 URL |
| email | string | | 이메일 (Google 로그인 시) |
| currentCrewId | string | | 현재 활동 중인 크루 ID |
| createdAt | timestamp | ✓ | 계정 생성 시각 |
| updatedAt | timestamp | ✓ | 마지막 수정 시각 |

---

## 2. crews/{crewId}

**경로**: `crews/{crewId}`
**문서 ID**: 자동 생성 또는 커스텀 slug

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| name | string | ✓ | 크루 이름 |
| description | string | | 크루 설명 |
| ownerUid | string | ✓ | 크루장 UID |
| inviteCode | string | | 초대 코드 |
| createdAt | timestamp | ✓ | 생성 시각 |
| updatedAt | timestamp | ✓ | 수정 시각 |

---

## 3. crews/{crewId}/members/{uid}

**경로**: `crews/{crewId}/members/{uid}`
**문서 ID**: 멤버의 Firebase Auth UID

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| displayName | string | ✓ | 표시 이름 (비정규화) |
| photoUrl | string | | 프로필 사진 URL |
| role | string | ✓ | 역할: `owner`, `admin`, `member` |
| joinedAt | timestamp | ✓ | 가입 시각 |

---

## 4. crews/{crewId}/joinRequests/{uid}

**경로**: `crews/{crewId}/joinRequests/{uid}`
**문서 ID**: 요청자의 Firebase Auth UID

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| displayName | string | ✓ | 요청자 이름 |
| photoUrl | string | | 프로필 사진 URL |
| status | string | ✓ | 상태: `pending`, `approved`, `rejected` |
| message | string | | 가입 메시지 |
| requestedAt | timestamp | ✓ | 요청 시각 |
| processedAt | timestamp | | 처리 시각 |
| processedBy | string | | 처리자 UID |

---

## 5. crews/{crewId}/workouts/{workoutId}

**경로**: `crews/{crewId}/workouts/{workoutId}`
**문서 ID**: `{uid}_{dateKey}` (예: `user123_2024-01-15`)

### 문서 ID 규칙
- 형식: `{uid}_{dateKey}`
- 예시: `abc123_2024-01-15`
- **하루 1회 인증 강제**: 동일 uid + dateKey 조합은 하나의 문서만 존재

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| uid | string | ✓ | 사용자 UID |
| dateKey | string | ✓ | 날짜 키 (YYYY-MM-DD) |
| weekKey | string | ✓ | 주 키 (해당 주 월요일의 dateKey) |
| type | string | ✓ | 운동 종류 (러닝, 헬스 등) |
| memo | string | | 메모 |
| photoUrl | string | | 인증 사진 URL |
| photoPath | string | | Storage 경로 (삭제용) |
| createdAt | timestamp | ✓ | 생성 시각 |
| updatedAt | timestamp | ✓ | 수정 시각 |

---

## 키 규칙

### dateKey
- 형식: `YYYY-MM-DD`
- 예시: `2024-01-15`
- 용도: 일별 인증 구분

### weekKey
- 형식: `YYYY-MM-DD` (해당 주 월요일의 dateKey)
- 예시: 2024-01-17(수요일) → `2024-01-15`(월요일)
- 용도: 주간 통계 그룹핑
- 기준: ISO 8601 (월요일 시작)

### workoutId
- 형식: `{uid}_{dateKey}`
- 예시: `abc123_2024-01-15`
- 용도: 하루 1회 인증 강제

---

## 쿼리 예시

### 주간 통계 조회
```dart
firestore
  .collection('crews')
  .doc(crewId)
  .collection('workouts')
  .where('weekKey', isEqualTo: '2024-01-15')
  .get();
```

### 특정 사용자의 이번 달 기록
```dart
firestore
  .collection('crews')
  .doc(crewId)
  .collection('workouts')
  .where('uid', isEqualTo: uid)
  .where('dateKey', isGreaterThanOrEqualTo: '2024-01-01')
  .where('dateKey', isLessThanOrEqualTo: '2024-01-31')
  .get();
```

### 오늘 인증 여부 확인
```dart
final workoutId = '${uid}_${toDateKey(DateTime.now())}';
final doc = await firestore
  .collection('crews')
  .doc(crewId)
  .collection('workouts')
  .doc(workoutId)
  .get();
final hasWorkoutToday = doc.exists;
```
