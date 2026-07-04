import 'package:drift/drift.dart';
import '../database/app_database.dart';
import 'exercise_master_repository.dart';

class DriftExerciseMasterRepository implements ExerciseMasterRepository {
  final AppDatabase _db;

  DriftExerciseMasterRepository(this._db);

  @override
  Future<List<ExerciseMaster>> findAll() {
    return (_db.select(
      _db.exerciseMasters,
    )..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])).get();
  }

  @override
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

  @override
  Future<void> updateName(int exerciseId, String name) {
    return (_db.update(_db.exerciseMasters)
          ..where((t) => t.exerciseId.equals(exerciseId)))
        .write(ExerciseMastersCompanion(name: Value(name)));
  }

  @override
  Future<void> delete(int exerciseId) {
    return (_db.delete(
      _db.exerciseMasters,
    )..where((t) => t.exerciseId.equals(exerciseId))).go();
  }

  @override
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
