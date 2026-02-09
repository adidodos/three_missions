import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'firebase_options.dart';
import 'core/router/router.dart';
import 'core/theme/theme.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/crew/data/crew_repository.dart';
import 'features/members/data/member_repository.dart';
import 'features/exercise_types/data/exercise_type_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize date formatting for Korean
  await initializeDateFormatting('ko');

  // Initialize app data
  await _initializeAppData();

  runApp(
    const ProviderScope(
      child: ThreeMissionsApp(),
    ),
  );
}

Future<void> _initializeAppData() async {
  try {
    final authRepo = AuthRepository();
    final crewRepo = CrewRepository();
    final memberRepo = MemberRepository();
    final exerciseTypeRepo = ExerciseTypeRepository();

    // Sign in anonymously
    var user = authRepo.currentUser;
    if (user == null) {
      user = await authRepo.signInAnonymously();
    }

    if (user == null) {
      debugPrint('Anonymous sign-in failed');
      return;
    }

    debugPrint('Signed in as: ${user.uid}');

    const crewId = CrewRepository.defaultCrewId;

    // Create default crew
    await crewRepo.createDefaultCrew(user.uid);
    debugPrint('Default crew created/verified');

    // Ensure "me" member exists
    await memberRepo.ensureMyMember(crewId, user.uid);
    debugPrint('My member created/verified');

    // Seed default exercise types
    await exerciseTypeRepo.seedDefaultTypes(crewId);
    debugPrint('Exercise types seeded');
  } catch (e) {
    debugPrint('Initialization error: $e');
    // 앱은 계속 실행되도록 함
  }
}

class ThreeMissionsApp extends StatelessWidget {
  const ThreeMissionsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Three Missions',
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
