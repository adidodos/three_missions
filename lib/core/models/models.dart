/// Core data models for three_missions app.
///
/// Firestore collection structure:
/// ```
/// /users/{uid}                           - UserProfile
/// /crews/{crewId}                        - Crew
/// /crews/{crewId}/members/{uid}          - Member
/// /crews/{crewId}/joinRequests/{uid}     - JoinRequest
/// /crews/{crewId}/workouts/{workoutId}   - Workout
/// ```
///
/// See [docs/firestore_structure.md] for detailed documentation.
library;

export 'crew.dart';
export 'join_request.dart';
export 'member.dart';
export 'user_profile.dart';
export 'workout.dart';
