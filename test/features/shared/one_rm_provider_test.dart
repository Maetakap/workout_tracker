import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/data/database/app_database.dart';
import 'package:workout_tracker/data/providers.dart';
import 'package:workout_tracker/data/repositories/workout_set_repository.dart';
import 'package:workout_tracker/features/shared/one_rm_provider.dart';
import '../../helpers/notifier_test_helpers.dart';

/// findAll()だけ実装するフェイクRepository
class _FakeWorkoutSetRepository implements WorkoutSetRepository {
  _FakeWorkoutSetRepository(this._sets);

  final List<WorkoutSet> _sets;

  @override
  Future<List<WorkoutSet>> findAll() async => _sets;

  @override
  noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('未使用メソッド: ${invocation.memberName}');
}

WorkoutSet makeSet({
  required int exerciseId,
  required double weightKg,
  required int reps,
}) {
  return WorkoutSet(
    setId: 0,
    sessionId: 0,
    exerciseId: exerciseId,
    setOrder: 0,
    weightKg: weightKg,
    reps: reps,
    rir: 0,
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  group('exerciseOneRmProvider', () {
    test('記録なし：空Mapを返す', () async {
      final container = createContainer(
        overrides: [
          workoutSetRepositoryProvider.overrideWithValue(
            _FakeWorkoutSetRepository([]),
          ),
        ],
      );
      final result = await container.read(exerciseOneRmProvider.future);
      expect(result, isEmpty);
    });

    test('単一種目・単一セット：その1RMを返す', () async {
      final container = createContainer(
        overrides: [
          workoutSetRepositoryProvider.overrideWithValue(
            _FakeWorkoutSetRepository([
              makeSet(exerciseId: 1, weightKg: 100, reps: 1),
            ]),
          ),
        ],
      );
      final result = await container.read(exerciseOneRmProvider.future);
      expect(result[1], closeTo(100.0, 0.01));
    });

    test('単一種目・複数セット：最大の1RMを採用', () async {
      // 100kg×1rep=100.0, 80kg×8rep=101.33... → 後者が最大
      final container = createContainer(
        overrides: [
          workoutSetRepositoryProvider.overrideWithValue(
            _FakeWorkoutSetRepository([
              makeSet(exerciseId: 1, weightKg: 100, reps: 1),
              makeSet(exerciseId: 1, weightKg: 80, reps: 8),
            ]),
          ),
        ],
      );
      final result = await container.read(exerciseOneRmProvider.future);
      expect(result[1], closeTo(101.33, 0.01));
    });

    test('複数種目：種目ごとに最大1RMが分かれる', () async {
      final container = createContainer(
        overrides: [
          workoutSetRepositoryProvider.overrideWithValue(
            _FakeWorkoutSetRepository([
              makeSet(exerciseId: 1, weightKg: 100, reps: 5), // 116.67
              makeSet(exerciseId: 2, weightKg: 60, reps: 10), // 80.0
            ]),
          ),
        ],
      );
      final result = await container.read(exerciseOneRmProvider.future);
      expect(result[1], closeTo(116.67, 0.01));
      expect(result[2], closeTo(80.0, 0.01));
    });

    test('記録のない種目はキーを持たない', () async {
      final container = createContainer(
        overrides: [
          workoutSetRepositoryProvider.overrideWithValue(
            _FakeWorkoutSetRepository([
              makeSet(exerciseId: 1, weightKg: 100, reps: 5),
            ]),
          ),
        ],
      );
      final result = await container.read(exerciseOneRmProvider.future);
      expect(result.containsKey(1), isTrue);
      expect(result.containsKey(99), isFalse);
    });
  });
}
