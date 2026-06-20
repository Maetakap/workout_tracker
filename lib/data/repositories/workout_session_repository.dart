import 'package:drift/drift.dart';
import '../database/app_database.dart';

class WorkoutSessionRepository {
  final AppDatabase _db;

  WorkoutSessionRepository(this._db);

  /// 全セッションを新しい順に取得
  Future<List<WorkoutSession>> findAll() {
    return (_db.select(
      _db.workoutSessions,
    )..orderBy([(t) => OrderingTerm.desc(t.date)])).get();
  }

  /// 月フィルター＋種目フィルターで取得
  Future<List<WorkoutSession>> findByFilter({
    DateTime? monthStart,
    DateTime? monthEnd,
    int? exerciseId,
  }) async {
    // 種目フィルターがある場合は該当setが存在するsessionIdを先に取得
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

  /// IDで1件取得
  Future<WorkoutSession?> findById(int sessionId) {
    return (_db.select(
      _db.workoutSessions,
    )..where((t) => t.sessionId.equals(sessionId))).getSingleOrNull();
  }

  /// セッション追加（sessionIdを返す）
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

  /// セッション更新
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

  /// セッション削除
  Future<void> delete(int sessionId) {
    return (_db.delete(
      _db.workoutSessions,
    )..where((t) => t.sessionId.equals(sessionId))).go();
  }
}
