import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/models/wall_post.dart';
import '../../core/repositories/location_repository.dart';
import '../../core/repositories/wall_post_repository.dart';

// ── 레포지토리 ──────────────────────────────────────────────────────────────

final wallPostRepositoryProvider = Provider<WallPostRepository>((ref) {
  return WallPostRepository();
});

final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  return LocationRepository();
});

// ── 담벼락 필터 ─────────────────────────────────────────────────────────────

enum WallFilter { dong, sigungu, all }

class _WallFilterNotifier extends Notifier<WallFilter> {
  @override
  WallFilter build() => WallFilter.dong;

  void set(WallFilter f) => state = f;
}

final wallFilterProvider = NotifierProvider<_WallFilterNotifier, WallFilter>(
  _WallFilterNotifier.new,
);

// ── 담벼락 글 목록 ───────────────────────────────────────────────────────────

final wallPostsProvider = StreamProvider<List<WallPost>>((ref) {
  final filter = ref.watch(wallFilterProvider);
  final profile = ref.watch(userProfileProvider).value;
  final repo = ref.read(wallPostRepositoryProvider);

  if (filter == WallFilter.dong) {
    final dong = profile?.dong;
    if (dong == null || dong.isEmpty) return repo.watchAll();
    return repo.watchByDong(dong);
  } else if (filter == WallFilter.sigungu) {
    final sigungu = profile?.sigungu;
    if (sigungu == null || sigungu.isEmpty) return repo.watchAll();
    return repo.watchBySigungu(sigungu);
  } else {
    return repo.watchAll();
  }
});

// ── 특정 크루 홍보글 ─────────────────────────────────────────────────────────

final crewWallPostProvider =
    FutureProvider.family<WallPost?, String>((ref, crewId) async {
  final repo = ref.read(wallPostRepositoryProvider);
  return repo.getPost(crewId);
});

// ── 위치 선택용 ──────────────────────────────────────────────────────────────

final sidoListProvider = FutureProvider<List<String>>((ref) async {
  final repo = ref.read(locationRepositoryProvider);
  return repo.getSidoList();
});

final sigunguListProvider =
    FutureProvider.family<List<String>, String>((ref, sido) async {
  final repo = ref.read(locationRepositoryProvider);
  return repo.getSigunguList(sido);
});

final dongListProvider =
    FutureProvider.family<List<String>, (String, String)>((ref, args) async {
  final (sido, sigungu) = args;
  final repo = ref.read(locationRepositoryProvider);
  return repo.getDongList(sido, sigungu);
});
