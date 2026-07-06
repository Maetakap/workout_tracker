import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/data/database/app_database.dart';
import 'package:workout_tracker/data/providers.dart';
import 'package:workout_tracker/data/repositories/interface/exercise_master_repository.dart';
import 'package:workout_tracker/data/repositories/interface/set_input.dart';
import 'package:workout_tracker/data/repositories/interface/workout_session_repository.dart';
import 'package:workout_tracker/data/repositories/interface/workout_set_repository.dart';
import 'package:workout_tracker/features/workout_input/workout_input_notifier.dart';

import '../../helpers/notifier_test_helpers.dart';

/// セッション保存を記録するフェイクRepository
class FakeSessionRepo implements WorkoutSessionRepository {
  bool throwOnSave = false;
  int? savedFocusLevel;
  String? savedMemo;
  List<SetInput> savedSets = [];

  @override
  Future<List<WorkoutSession>> findAll() async => [];

  @override
  Future<int> createSessionWithSets({
    required DateTime date,
    required int focusLevel,
    String? memo,
    required List<SetInput> sets,
  }) async {
    if (throwOnSave) throw Exception('DB error');
    savedFocusLevel = focusLevel;
    savedMemo = memo;
    savedSets = sets;
    return 1; // sessionId
  }

  @override
  noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} は未使用');
}

/// セット保存を記録するフェイクRepository
class FakeSetRepo implements WorkoutSetRepository {
  List<WorkoutSetsCompanion> insertedSets = [];

  @override
  Future<List<WorkoutSet>> findAll() async => [];

  @override
  Future<void> insertAll(List<WorkoutSetsCompanion> sets) async {
    insertedSets = sets;
  }

  @override
  noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} は未使用');
}

/// 種目用フェイクRepository
class FakeExerciseRepo implements ExerciseMasterRepository {
  @override
  Future<List<ExerciseMaster>> findAll() async => [];

  @override
  noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} は未使用');
}

void main() {
  late FakeSessionRepo fakeSessionRepo;
  late FakeSetRepo fakeSetRepo;
  late FakeExerciseRepo fakeExerciseRepo;

  setUp(() {
    fakeSessionRepo = FakeSessionRepo();
    fakeSetRepo = FakeSetRepo();
    fakeExerciseRepo = FakeExerciseRepo();
  });

  createTestContainer() => createContainer(
    overrides: [
      workoutSessionRepositoryProvider.overrideWithValue(fakeSessionRepo),
      workoutSetRepositoryProvider.overrideWithValue(fakeSetRepo),
      exerciseMasterRepositoryProvider.overrideWithValue(fakeExerciseRepo),
    ],
  );

  group('WorkoutInputNotifier 状態操作', () {
    test('初期状態はカード1件・focusLevelがnull', () {
      final container = createTestContainer();
      final state = container.read(workoutInputProvider);
      expect(state.exerciseCards.length, 1);
      expect(state.focusLevel, null);
      expect(state.isSaving, false);
    });

    test('addExerciseCard()でカードが増える', () {
      final container = createTestContainer();
      container.read(workoutInputProvider.notifier).addExerciseCard();
      expect(container.read(workoutInputProvider).exerciseCards.length, 2);
    });

    test('removeExerciseCard()は2枚以上のとき削除できる', () {
      final container = createTestContainer();
      final notifier = container.read(workoutInputProvider.notifier);
      notifier.addExerciseCard();
      notifier.removeExerciseCard(0);
      expect(container.read(workoutInputProvider).exerciseCards.length, 1);
    });

    test('removeExerciseCard()は1枚のときは削除しない', () {
      final container = createTestContainer();
      container.read(workoutInputProvider.notifier).removeExerciseCard(0);
      expect(container.read(workoutInputProvider).exerciseCards.length, 1);
    });

    test('addSet()は前セットのweightKgのみコピーする', () {
      final container = createTestContainer();
      final notifier = container.read(workoutInputProvider.notifier);
      notifier.updateWeight(0, 0, 60.0);
      notifier.updateReps(0, 0, 10);
      notifier.updateRir(0, 0, 2);
      notifier.addSet(0);

      final sets = container.read(workoutInputProvider).exerciseCards[0].sets;
      expect(sets.length, 2);
      expect(sets[1].weightKg, 60.0);
      expect(sets[1].reps, null);
      expect(sets[1].rir, null);
    });

    test('removeSet()は2件以上のとき削除できる', () {
      final container = createTestContainer();
      final notifier = container.read(workoutInputProvider.notifier);
      notifier.addSet(0);
      notifier.removeSet(0, 0);
      expect(
        container.read(workoutInputProvider).exerciseCards[0].sets.length,
        1,
      );
    });

    test('removeSet()は1件のときは削除しない', () {
      final container = createTestContainer();
      container.read(workoutInputProvider.notifier).removeSet(0, 0);
      expect(
        container.read(workoutInputProvider).exerciseCards[0].sets.length,
        1,
      );
    });

    test('updateWeight()は指定セットのみ更新する', () {
      final container = createTestContainer();
      final notifier = container.read(workoutInputProvider.notifier);
      notifier.addSet(0);
      notifier.updateWeight(0, 0, 80.0);
      final sets = container.read(workoutInputProvider).exerciseCards[0].sets;
      expect(sets[0].weightKg, 80.0);
      expect(sets[1].weightKg, null);
    });

    test('setFocusLevel()でfocusLevelが更新される', () {
      final container = createTestContainer();
      container.read(workoutInputProvider.notifier).setFocusLevel(4);
      expect(container.read(workoutInputProvider).focusLevel, 4);
    });

    test('setMemo()でmemoが更新される', () {
      final container = createTestContainer();
      container.read(workoutInputProvider.notifier).setMemo('テストメモ');
      expect(container.read(workoutInputProvider).memo, 'テストメモ');
    });
  });

  group('WorkoutInputNotifier saveSession', () {
    // canSave()がtrueになる状態をセットアップ
    void fillValidInput(container) {
      final notifier = container.read(workoutInputProvider.notifier);
      notifier.setExerciseId(0, 1);
      notifier.updateWeight(0, 0, 60.0);
      notifier.updateReps(0, 0, 10);
      notifier.updateRir(0, 0, 2);
      notifier.setFocusLevel(3);
    }

    test('保存成功で状態がリセットされる', () async {
      final container = createTestContainer();
      fillValidInput(container);
      container.read(workoutInputProvider.notifier).setMemo('がんばった');

      await container.read(workoutInputProvider.notifier).saveSession();
      await settle();

      // Repositoryに正しい値が渡る
      expect(fakeSessionRepo.savedFocusLevel, 3);
      expect(fakeSessionRepo.savedMemo, 'がんばった');
      expect(fakeSessionRepo.savedSets.length, 1);

      // 保存後リセット
      final state = container.read(workoutInputProvider);
      expect(state.focusLevel, null);
      expect(state.isSaving, false);
    });

    test('保存したセットにsetOrderが通し番号で振られる', () async {
      final container = createTestContainer();
      final notifier = container.read(workoutInputProvider.notifier);
      notifier.setExerciseId(0, 1);
      notifier.updateWeight(0, 0, 60.0);
      notifier.updateReps(0, 0, 10);
      notifier.updateRir(0, 0, 2);
      notifier.addSet(0);
      notifier.updateReps(0, 1, 8);
      notifier.updateRir(0, 1, 3);
      notifier.setFocusLevel(3);

      await notifier.saveSession();
      await settle();

      final sets = fakeSessionRepo.savedSets;
      expect(sets.length, 2);
      expect(sets[0].setOrder, 0);
      expect(sets[1].setOrder, 1);
    });

    test('Repository失敗時はisSavingがfalseに戻る', () async {
      final container = createTestContainer();
      fillValidInput(container);
      fakeSessionRepo.throwOnSave = true;

      try {
        await container.read(workoutInputProvider.notifier).saveSession();
      } catch (_) {}
      await settle();

      expect(container.read(workoutInputProvider).isSaving, false);
    });
  });
}
