import '../../database/app_database.dart';

abstract interface class WorkoutSetRepository {
  Future<List<WorkoutSet>> findBySessionId(int sessionId);
  Future<void> deleteBySessionId(int sessionId);
  Future<List<WorkoutSet>> findAll();
}
