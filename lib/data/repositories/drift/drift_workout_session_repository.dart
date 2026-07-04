import 'package:drift/drift.dart';
import '../../database/app_database.dart';
import '../interface/workout_session_repository.dart';

class DriftWorkoutSessionRepository implements WorkoutSessionRepository {
  final AppDatabase _db;

  DriftWorkoutSessionRepository(this._db);

  @override
  Future<List<WorkoutSession>> findAll() {
    return (_db.select(
      _db.workoutSessions,
    )..orderBy([(t) => OrderingTerm.desc(t.date)])).get();
  }

  @override
  Future<List<WorkoutSession>> findByFilter({
    DateTime? monthStart,
    DateTime? monthEnd,
    int? exerciseId,
  }) async {
    Set<int>? filteredSessionIds;
    if (exerciseId != null) {
      final sets = await (_db.select(
        _db.workoutSets,
      )..where((t) => t.exerciseId.equals(exerciseId))).get();
      filteredSessionIds = sets.map((s) => s.sessionId).toSet();
      if (filteredSessionIds.isEmpty) return [];
    }

    final query = _db.select(_db.workoutSessions)
      ..orderBy([(t) => OrderingTerm.desc(t.date)]);

    query.where((t) {
      Expression<bool> cond = const Constant(true);
      if (monthStart != null) {
        cond = cond & t.date.isBiggerOrEqualValue(monthStart);
      }
      if (monthEnd != null) {
        cond = cond & t.date.isSmallerThanValue(monthEnd);
      }
      if (filteredSessionIds != null) {
        cond = cond & t.sessionId.isIn(filteredSessionIds.toList());
      }
      return cond;
    });

    return query.get();
  }

  @override
  Future<WorkoutSession?> findById(int sessionId) {
    return (_db.select(
      _db.workoutSessions,
    )..where((t) => t.sessionId.equals(sessionId))).getSingleOrNull();
  }

  @override
  Future<int> insert({
    required DateTime date,
    required int focusLevel,
    String? memo,
  }) {
    return _db
        .into(_db.workoutSessions)
        .insert(
          WorkoutSessionsCompanion.insert(
            date: date,
            focusLevel: focusLevel,
            memo: Value(memo),
            createdAt: DateTime.now(),
          ),
        );
  }

  @override
  Future<void> update({
    required int sessionId,
    required DateTime date,
    required int focusLevel,
    String? memo,
  }) {
    return (_db.update(
      _db.workoutSessions,
    )..where((t) => t.sessionId.equals(sessionId))).write(
      WorkoutSessionsCompanion(
        date: Value(date),
        focusLevel: Value(focusLevel),
        memo: Value(memo),
      ),
    );
  }

  @override
  Future<void> delete(int sessionId) {
    return (_db.delete(
      _db.workoutSessions,
    )..where((t) => t.sessionId.equals(sessionId))).go();
  }
}
