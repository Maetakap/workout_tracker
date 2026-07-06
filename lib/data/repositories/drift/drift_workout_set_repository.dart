import 'package:drift/drift.dart';
import '../../database/app_database.dart';
import '../interface/workout_set_repository.dart';

class DriftWorkoutSetRepository implements WorkoutSetRepository {
  final AppDatabase _db;

  DriftWorkoutSetRepository(this._db);

  @override
  Future<List<WorkoutSet>> findBySessionId(int sessionId) {
    return (_db.select(_db.workoutSets)
          ..where((t) => t.sessionId.equals(sessionId))
          ..orderBy([(t) => OrderingTerm.asc(t.setOrder)]))
        .get();
  }

  @override
  Future<void> deleteBySessionId(int sessionId) {
    return (_db.delete(
      _db.workoutSets,
    )..where((t) => t.sessionId.equals(sessionId))).go();
  }

  @override
  Future<List<WorkoutSet>> findAll() {
    return _db.select(_db.workoutSets).get();
  }
}
