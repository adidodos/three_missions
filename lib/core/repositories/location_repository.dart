import 'dart:convert';
import 'package:flutter/services.dart';

/// JSON 번들 에셋에서 한국 행정구역 데이터를 로드합니다.
/// 구조: { 시도: { 시군구: [동1, 동2, ...] } }
class LocationRepository {
  static Map<String, Map<String, List<String>>>? _cache;

  Future<Map<String, Map<String, List<String>>>> loadAll() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/data/kr_locations.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    _cache = decoded.map(
      (sido, sigunguMap) => MapEntry(
        sido,
        (sigunguMap as Map<String, dynamic>).map(
          (sigungu, dongList) => MapEntry(
            sigungu,
            (dongList as List<dynamic>).cast<String>(),
          ),
        ),
      ),
    );
    return _cache!;
  }

  Future<List<String>> getSidoList() async {
    final all = await loadAll();
    return all.keys.toList();
  }

  Future<List<String>> getSigunguList(String sido) async {
    final all = await loadAll();
    return all[sido]?.keys.toList() ?? [];
  }

  Future<List<String>> getDongList(String sido, String sigungu) async {
    final all = await loadAll();
    return all[sido]?[sigungu] ?? [];
  }
}
