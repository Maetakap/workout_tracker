import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'database/app_database.dart';
import 'repositories/interface/exercise_master_repository.dart';
import 'repositories/interface/workout_session_repository.dart';
import 'repositories/interface/workout_set_repository.dart';
import 'repositories/drift/drift_exercise_master_repository.dart';
import 'repositories/drift/drift_workout_session_repository.dart';
import 'repositories/drift/drift_workout_set_repository.dart';
import 'repositories/supabase/supabase_exercise_master_repository.dart';
import 'repositories/supabase/supabase_workout_session_repository.dart';
import 'repositories/supabase/supabase_workout_set_repository.dart';

/// DBインスタンス
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Repositoryプロバイダー
final exerciseMasterRepositoryProvider = Provider<ExerciseMasterRepository>((
  ref,
) {
  if (kIsWeb) {
    return SupabaseExerciseMasterRepository(Supabase.instance.client);
  }
  return DriftExerciseMasterRepository(ref.watch(appDatabaseProvider));
});

final workoutSessionRepositoryProvider = Provider<WorkoutSessionRepository>((
  ref,
) {
  if (kIsWeb) {
    return SupabaseWorkoutSessionRepository(Supabase.instance.client);
  }
  return DriftWorkoutSessionRepository(ref.watch(appDatabaseProvider));
});

final workoutSetRepositoryProvider = Provider<WorkoutSetRepository>((ref) {
  if (kIsWeb) {
    return SupabaseWorkoutSetRepository(Supabase.instance.client);
  }
  return DriftWorkoutSetRepository(ref.watch(appDatabaseProvider));
});
