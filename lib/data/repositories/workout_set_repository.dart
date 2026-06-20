import 'package:drift/drift.dart';
import '../database/app_database.dart';

class WorkoutSetRepository {
  final AppDatabase _db;

  WorkoutSetRepository(this._db);

  /// セッションに紐づく全セットをsetOrder順に取得
  Future<List<WorkoutSet>> findBySessionId(int sessionId) {
    return (_db.select(_db.workoutSets)
          ..where((t) => t.sessionId.equals(sessionId))
          ..orderBy([(t) => OrderingTerm.asc(t.setOrder)]))
        .get();
  }

  /// セットを一括insert（トランザクション）
  Future<void> insertAll(List<WorkoutSetsCompanion> sets) async {
    await _db.transaction(() async {
      for (final set in sets) {
        await _db.into(_db.workoutSets).insert(set);
      }
    });
  }

  /// セッションに紐づく全セットを削除してから一括insert（編集時に使用）
  Future<void> replaceAll(
    int sessionId,
    List<WorkoutSetsCompanion> sets,
  ) async {
    await _db.transaction(() async {
      await (_db.delete(
        _db.workoutSets,
      )..where((t) => t.sessionId.equals(sessionId))).go();
      for (final set in sets) {
        await _db.into(_db.workoutSets).insert(set);
      }
    });
  }

  /// セッションに紐づく全セットを削除（セッション削除時に使用）
  Future<void> deleteBySessionId(int sessionId) {
    return (_db.delete(
      _db.workoutSets,
    )..where((t) => t.sessionId.equals(sessionId))).go();
  }

  /// 全セットを取得（一覧画面の種目名表示・フィルター用）
  Future<List<WorkoutSet>> findAll() {
    return _db.select(_db.workoutSets).get();
  }
}
