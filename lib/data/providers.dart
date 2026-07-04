import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'database/app_database.dart';
import 'repositories/exercise_master_repository.dart';
import 'repositories/drift_exercise_master_repository.dart';
import 'repositories/supabase_exercise_master_repository.dart';
import 'repositories/workout_session_repository.dart';
import 'repositories/workout_set_repository.dart';

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
  return WorkoutSessionRepository(ref.watch(appDatabaseProvider));
});

final workoutSetRepositoryProvider = Provider<WorkoutSetRepository>((ref) {
  return WorkoutSetRepository(ref.watch(appDatabaseProvider));
});
