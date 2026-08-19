import 'package:drift/drift.dart';
import '../../database/app_database.dart';
import '../interface/set_input.dart';
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

  @override
  Future<int> createSessionWithSets({
    required DateTime date,
    required int focusLevel,
    String? memo,
    required List<SetInput> sets,
  }) async {
    return _db.transaction(() async {
      // セッションをinsertしてsessionIdを採番
      final sessionId = await _db
          .into(_db.workoutSessions)
          .insert(
            WorkoutSessionsCompanion.insert(
              date: date,
              focusLevel: focusLevel,
              memo: Value(memo),
              createdAt: DateTime.now(),
            ),
          );

      // 採番されたsessionIdでセット群をinsert
      for (final s in sets) {
        await _db
            .into(_db.workoutSets)
            .insert(
              WorkoutSetsCompanion.insert(
                sessionId: sessionId,
                exerciseId: s.exerciseId,
                setOrder: s.setOrder,
                weightKg: s.weightKg,
                reps: s.reps,
                rir: s.rir,
                createdAt: DateTime.now(),
              ),
            );
      }

      return sessionId;
    });
  }

  @override
  Future<void> updateSessionWithSets({
    required int sessionId,
    required DateTime date,
    required int focusLevel,
    String? memo,
    required List<SetInput> sets,
  }) async {
    await _db.transaction(() async {
      // セッションをupdate
      await (_db.update(
        _db.workoutSessions,
      )..where((t) => t.sessionId.equals(sessionId))).write(
        WorkoutSessionsCompanion(
          date: Value(date),
          focusLevel: Value(focusLevel),
          memo: Value(memo),
        ),
      );

      // セットを全置換（削除→insert）
      await (_db.delete(
        _db.workoutSets,
      )..where((t) => t.sessionId.equals(sessionId))).go();

      for (final s in sets) {
        await _db
            .into(_db.workoutSets)
            .insert(
              WorkoutSetsCompanion.insert(
                sessionId: sessionId,
                exerciseId: s.exerciseId,
                setOrder: s.setOrder,
                weightKg: s.weightKg,
                reps: s.reps,
                rir: s.rir,
                createdAt: DateTime.now(),
              ),
            );
      }
    });
  }
}
