import '../../database/app_database.dart';

abstract interface class WorkoutSessionRepository {
  Future<List<WorkoutSession>> findAll();
  Future<List<WorkoutSession>> findByFilter({
    DateTime? monthStart,
    DateTime? monthEnd,
    int? exerciseId,
  });
  Future<WorkoutSession?> findById(int sessionId);
  Future<int> insert({
    required DateTime date,
    required int focusLevel,
    String? memo,
  });
  Future<void> update({
    required int sessionId,
    required DateTime date,
    required int focusLevel,
    String? memo,
  });
  Future<void> delete(int sessionId);
}
