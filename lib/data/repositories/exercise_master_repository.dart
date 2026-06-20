import 'package:drift/drift.dart';
import '../database/app_database.dart';

class ExerciseMasterRepository {
  final AppDatabase _db;

  ExerciseMasterRepository(this._db);

  /// 全種目を取得（表示順）
  Future<List<ExerciseMaster>> findAll() {
    return (_db.select(
      _db.exerciseMasters,
    )..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])).get();
  }

  /// 種目追加
  Future<int> insert(String name, int sortOrder) {
    return _db
        .into(_db.exerciseMasters)
        .insert(
          ExerciseMastersCompanion.insert(
            name: name,
            sortOrder: sortOrder,
            createdAt: DateTime.now(),
          ),
        );
  }

  /// 名前更新
  Future<void> updateName(int exerciseId, String name) {
    return (_db.update(_db.exerciseMasters)
          ..where((t) => t.exerciseId.equals(exerciseId)))
        .write(ExerciseMastersCompanion(name: Value(name)));
  }

  /// 削除
  Future<void> delete(int exerciseId) {
    return (_db.delete(
      _db.exerciseMasters,
    )..where((t) => t.exerciseId.equals(exerciseId))).go();
  }

  /// 表示順を一括更新
  Future<void> updateSortOrders(List<ExerciseMaster> exercises) async {
    await _db.transaction(() async {
      for (var i = 0; i < exercises.length; i++) {
        await (_db.update(_db.exerciseMasters)
              ..where((t) => t.exerciseId.equals(exercises[i].exerciseId)))
            .write(ExerciseMastersCompanion(sortOrder: Value(i)));
      }
    });
  }
}
