import '../../database/app_database.dart';

abstract interface class WorkoutSetRepository {
  Future<List<WorkoutSet>> findBySessionId(int sessionId);
  Future<void> insertAll(List<WorkoutSetsCompanion> sets);
  Future<void> replaceAll(int sessionId, List<WorkoutSetsCompanion> sets);
  Future<void> deleteBySessionId(int sessionId);
  Future<List<WorkoutSet>> findAll();
}
