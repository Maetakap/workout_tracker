import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/data/database/app_database.dart';
import 'package:workout_tracker/data/providers.dart';
import 'package:workout_tracker/data/repositories/interface/exercise_master_repository.dart';
import 'package:workout_tracker/data/repositories/interface/workout_session_repository.dart';
import 'package:workout_tracker/data/repositories/interface/workout_set_repository.dart';
import 'package:workout_tracker/features/workout_list/workout_list_notifier.dart';

import '../../helpers/notifier_test_helpers.dart';

/// セッション用フェイクRepository
class FakeSessionRepo implements WorkoutSessionRepository {
  List<WorkoutSession> sessions = [];

  @override
  Future<List<WorkoutSession>> findAll() async => sessions;

  @override
  noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} は未使用');
}

/// セット用フェイクRepository
class FakeSetRepo implements WorkoutSetRepository {
  List<WorkoutSet> sets = [];

  @override
  Future<List<WorkoutSet>> findAll() async => sets;

  @override
  noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} は未使用');
}

/// 種目用フェイクRepository
class FakeExerciseRepo implements ExerciseMasterRepository {
  List<ExerciseMaster> exercises = [];

  @override
  Future<List<ExerciseMaster>> findAll() async => exercises;

  @override
  noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} は未使用');
}

void main() {
  late FakeSessionRepo fakeSessionRepo;
  late FakeSetRepo fakeSetRepo;
  late FakeExerciseRepo fakeExerciseRepo;

  WorkoutSession session({required int id, required DateTime date}) {
    return WorkoutSession(
      sessionId: id,
      date: date,
      focusLevel: 3,
      memo: null,
      createdAt: DateTime(2026, 1, 1),
    );
  }

  WorkoutSet set({
    required int setId,
    required int sessionId,
    required int exerciseId,
  }) {
    return WorkoutSet(
      setId: setId,
      sessionId: sessionId,
      exerciseId: exerciseId,
      setOrder: 0,
      weightKg: 60.0,
      reps: 10,
      rir: 2,
      createdAt: DateTime(2026, 1, 1),
    );
  }

  setUp(() {
    fakeSessionRepo = FakeSessionRepo();
    fakeSetRepo = FakeSetRepo();
    fakeExerciseRepo = FakeExerciseRepo();
  });

  /// フェイクRepositoryを使うcontainerを生成し、初回fetch完了を待つ
  Future<dynamic> createAndSettle() async {
    final container = createContainer(
      overrides: [
        workoutSessionRepositoryProvider.overrideWithValue(fakeSessionRepo),
        workoutSetRepositoryProvider.overrideWithValue(fakeSetRepo),
        exerciseMasterRepositoryProvider.overrideWithValue(fakeExerciseRepo),
      ],
    );
    // build()内の_fetchAllを完了させる
    container.read(workoutListProvider);
    await settle();
    return container;
  }

  group('WorkoutListNotifier フィルター', () {
    test('フィルターなしで全件表示される', () async {
      fakeSessionRepo.sessions = [
        session(id: 1, date: DateTime(2026, 6, 1)),
        session(id: 2, date: DateTime(2026, 5, 1)),
      ];
      final container = await createAndSettle();

      expect(container.read(workoutListProvider).filteredSessions.length, 2);
    });

    test('月フィルターで該当月のみ表示される', () async {
      fakeSessionRepo.sessions = [
        session(id: 1, date: DateTime(2026, 6, 1)),
        session(id: 2, date: DateTime(2026, 5, 1)),
      ];
      final container = await createAndSettle();

      container.read(workoutListProvider.notifier).setMonthFilter(202606);

      final filtered = container.read(workoutListProvider).filteredSessions;
      expect(filtered.length, 1);
      expect(filtered.first.sessionId, 1);
    });

    test('種目フィルターで該当種目を含むセッションのみ表示される', () async {
      fakeSessionRepo.sessions = [
        session(id: 1, date: DateTime(2026, 6, 1)),
        session(id: 2, date: DateTime(2026, 6, 2)),
      ];
      fakeSetRepo.sets = [
        set(setId: 1, sessionId: 1, exerciseId: 10),
        set(setId: 2, sessionId: 2, exerciseId: 20),
      ];
      final container = await createAndSettle();

      container.read(workoutListProvider.notifier).setExerciseFilter(10);

      final filtered = container.read(workoutListProvider).filteredSessions;
      expect(filtered.length, 1);
      expect(filtered.first.sessionId, 1);
    });

    test('月＋種目フィルターはAND条件で絞り込まれる', () async {
      fakeSessionRepo.sessions = [
        session(id: 1, date: DateTime(2026, 6, 1)), // 6月・種目10
        session(id: 2, date: DateTime(2026, 5, 1)), // 5月・種目10
        session(id: 3, date: DateTime(2026, 6, 2)), // 6月・種目20
      ];
      fakeSetRepo.sets = [
        set(setId: 1, sessionId: 1, exerciseId: 10),
        set(setId: 2, sessionId: 2, exerciseId: 10),
        set(setId: 3, sessionId: 3, exerciseId: 20),
      ];
      final container = await createAndSettle();

      container.read(workoutListProvider.notifier)
        ..setMonthFilter(202606)
        ..setExerciseFilter(10);

      // 6月 かつ 種目10 → session1のみ
      final filtered = container.read(workoutListProvider).filteredSessions;
      expect(filtered.length, 1);
      expect(filtered.first.sessionId, 1);
    });

    test('フィルター解除で全件に戻る', () async {
      fakeSessionRepo.sessions = [
        session(id: 1, date: DateTime(2026, 6, 1)),
        session(id: 2, date: DateTime(2026, 5, 1)),
      ];
      final container = await createAndSettle();

      final notifier = container.read(workoutListProvider.notifier);
      notifier.setMonthFilter(202606);
      expect(container.read(workoutListProvider).filteredSessions.length, 1);

      notifier.setMonthFilter(null);
      expect(container.read(workoutListProvider).filteredSessions.length, 2);
    });

    test('availableMonthsは月一覧を新しい順・重複なしで返す', () async {
      fakeSessionRepo.sessions = [
        session(id: 1, date: DateTime(2026, 6, 1)),
        session(id: 2, date: DateTime(2026, 5, 1)),
        session(id: 3, date: DateTime(2026, 6, 15)),
      ];
      final container = await createAndSettle();

      expect(container.read(workoutListProvider).availableMonths, [
        202606,
        202605,
      ]);
    });
  });
}
