import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/crew_repository.dart';

final crewRepositoryProvider = Provider<CrewRepository>((ref) {
  return CrewRepository();
});

final currentCrewIdProvider = Provider<String>((ref) {
  return CrewRepository.defaultCrewId;
});
