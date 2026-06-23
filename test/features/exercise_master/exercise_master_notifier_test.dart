import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/data/database/app_database.dart';
import 'package:workout_tracker/data/providers.dart';
import 'package:workout_tracker/data/repositories/exercise_master_repository.dart';
import 'package:workout_tracker/features/exercise_master/exercise_master_notifier.dart';

import '../../helpers/notifier_test_helpers.dart';

/// インメモリで動作するフェイクRepository。
/// 実DBを使わず、追加・削除・並び替えの結果を保持する。
class FakeExerciseMasterRepository implements ExerciseMasterRepository {
  final List<ExerciseMaster> _store = [];
  int _nextId = 1;

  @override
  Future<List<ExerciseMaster>> findAll() async {
    final sorted = [..._store]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return sorted;
  }

  @override
  Future<int> insert(String name, int sortOrder) async {
    final id = _nextId++;
    _store.add(
      ExerciseMaster(
        exerciseId: id,
        name: name,
        sortOrder: sortOrder,
        createdAt: DateTime(2026, 1, 1),
      ),
    );
    return id;
  }

  @override
  Future<void> updateName(int exerciseId, String name) async {
    final i = _store.indexWhere((e) => e.exerciseId == exerciseId);
    if (i != -1) {
      _store[i] = _store[i].copyWith(name: name);
    }
  }

  @override
  Future<void> delete(int exerciseId) async {
    _store.removeWhere((e) => e.exerciseId == exerciseId);
  }

  @override
  Future<void> updateSortOrders(List<ExerciseMaster> exercises) async {
    for (var i = 0; i < exercises.length; i++) {
      final idx = _store.indexWhere(
        (e) => e.exerciseId == exercises[i].exerciseId,
      );
      if (idx != -1) {
        _store[idx] = _store[idx].copyWith(sortOrder: i);
      }
    }
  }
}

void main() {
  late FakeExerciseMasterRepository fakeRepo;

  setUp(() {
    fakeRepo = FakeExerciseMasterRepository();
  });

  /// fakeRepoを使うcontainerを生成
  createTestContainer() => createContainer(
    overrides: [exerciseMasterRepositoryProvider.overrideWithValue(fakeRepo)],
  );

  group('ExerciseMasterNotifier', () {
    test('初期状態はexercisesが空', () {
      final container = createTestContainer();
      final state = container.read(exerciseMasterProvider);
      expect(state.exercises, isEmpty);
    });

    test('addExercise()で1件追加される', () async {
      final container = createTestContainer();
      await container
          .read(exerciseMasterProvider.notifier)
          .addExercise('ベンチプレス');

      final state = container.read(exerciseMasterProvider);
      expect(state.exercises.length, 1);
      expect(state.exercises.first.name, 'ベンチプレス');
    });

    test('addExercise()を2回呼ぶと2件になる', () async {
      final container = createTestContainer();
      final notifier = container.read(exerciseMasterProvider.notifier);
      await notifier.addExercise('ベンチプレス');
      await notifier.addExercise('スクワット');

      expect(container.read(exerciseMasterProvider).exercises.length, 2);
    });

    test('deleteExercise()で削除される', () async {
      final container = createTestContainer();
      final notifier = container.read(exerciseMasterProvider.notifier);
      await notifier.addExercise('ベンチプレス');

      final id = container
          .read(exerciseMasterProvider)
          .exercises
          .first
          .exerciseId;
      await notifier.deleteExercise(id);

      expect(container.read(exerciseMasterProvider).exercises, isEmpty);
    });

    test('updateName()で名前が更新される', () async {
      final container = createTestContainer();
      final notifier = container.read(exerciseMasterProvider.notifier);
      await notifier.addExercise('ベンチプレス');

      final id = container
          .read(exerciseMasterProvider)
          .exercises
          .first
          .exerciseId;
      await notifier.updateName(id, 'スクワット');

      expect(
        container.read(exerciseMasterProvider).exercises.first.name,
        'スクワット',
      );
    });

    test('reorder()で並び順が変わる', () async {
      final container = createTestContainer();
      final notifier = container.read(exerciseMasterProvider.notifier);
      await notifier.addExercise('ベンチプレス');
      await notifier.addExercise('スクワット');

      // 先頭(ベンチプレス)を末尾へ移動
      await notifier.reorder(0, 2);

      expect(
        container.read(exerciseMasterProvider).exercises.first.name,
        'スクワット',
      );
    });
  });
}
