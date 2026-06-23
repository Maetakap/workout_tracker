import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:workout_tracker/data/database/app_database.dart';
import 'package:workout_tracker/data/providers.dart';
import 'package:workout_tracker/data/repositories/exercise_master_repository.dart';
import 'package:workout_tracker/data/repositories/workout_session_repository.dart';
import 'package:workout_tracker/data/repositories/workout_set_repository.dart';
import 'package:workout_tracker/features/workout_list/workout_list_notifier.dart';
import 'package:workout_tracker/features/workout_list/workout_list_state.dart';

import 'workout_list_notifier_test.mocks.dart';

@GenerateMocks([
  WorkoutSessionRepository,
  WorkoutSetRepository,
  ExerciseMasterRepository,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockWorkoutSessionRepository mockSessionRepo;
  late MockWorkoutSetRepository mockSetRepo;
  late MockExerciseMasterRepository mockExerciseRepo;
  late ProviderContainer container;

  /// テスト用WorkoutSessionを生成
  WorkoutSession makeSession({
    required int id,
    required DateTime date,
    int focusLevel = 3,
    String? memo,
  }) {
    return WorkoutSession(
      sessionId: id,
      date: date,
      focusLevel: focusLevel,
      memo: memo,
      createdAt: DateTime(2026, 1, 1),
    );
  }

  /// テスト用WorkoutSetを生成
  WorkoutSet makeSet({
    required int setId,
    required int sessionId,
    required int exerciseId,
    int setOrder = 0,
  }) {
    return WorkoutSet(
      setId: setId,
      sessionId: sessionId,
      exerciseId: exerciseId,
      setOrder: setOrder,
      weightKg: 60.0,
      reps: 10,
      rir: 2,
      createdAt: DateTime(2026, 1, 1),
    );
  }

  setUp(() {
    mockSessionRepo = MockWorkoutSessionRepository();
    mockSetRepo = MockWorkoutSetRepository();
    mockExerciseRepo = MockExerciseMasterRepository();

    when(mockSessionRepo.findAll()).thenAnswer((_) async => []);
    when(mockSetRepo.findAll()).thenAnswer((_) async => []);
    when(mockExerciseRepo.findAll()).thenAnswer((_) async => []);

    container = ProviderContainer(
      overrides: [
        workoutSessionRepositoryProvider.overrideWithValue(mockSessionRepo),
        workoutSetRepositoryProvider.overrideWithValue(mockSetRepo),
        exerciseMasterRepositoryProvider.overrideWithValue(mockExerciseRepo),
      ],
    );
    addTearDown(() async {
      await Future.delayed(const Duration(milliseconds: 100));
      container.dispose();
    });
  });

  WorkoutListNotifier notifier() =>
      container.read(workoutListProvider.notifier);

  WorkoutListState currentState() => container.read(workoutListProvider);

  /// _fetchAllの完了を待つ
  Future<void> waitForFetch() =>
      Future.delayed(const Duration(milliseconds: 50));

  group('WorkoutListNotifier', () {
    test('1. 初期状態：sessionsが空・フィルターがデフォルト', () {
      expect(currentState().sessions, isEmpty);
      expect(currentState().selectedMonth, null);
      expect(currentState().selectedExerciseId, null);
      expect(currentState().isLoading, false);
    });

    test('2. fetchSessions()：全件取得してsessionsにセットされる', () async {
      final session = makeSession(id: 1, date: DateTime(2026, 6, 1));
      when(mockSessionRepo.findAll()).thenAnswer((_) async => [session]);
      when(mockSetRepo.findAll()).thenAnswer((_) async => []);
      when(mockExerciseRepo.findAll()).thenAnswer((_) async => []);

      container.listen(workoutListProvider, (_, _) {});
      await waitForFetch();

      expect(currentState().sessions.length, 1);
    });

    test('3. setMonthFilter()：指定月のセッションのみ表示される', () async {
      final june = makeSession(id: 1, date: DateTime(2026, 6, 1));
      final may = makeSession(id: 2, date: DateTime(2026, 5, 1));
      when(mockSessionRepo.findAll()).thenAnswer((_) async => [june, may]);
      when(mockSetRepo.findAll()).thenAnswer((_) async => []);
      when(mockExerciseRepo.findAll()).thenAnswer((_) async => []);

      // fetchAllを完了させる
      container.listen(workoutListProvider, (_, _) {});
      await waitForFetch();

      notifier().setMonthFilter(202606);

      final filtered = currentState().filteredSessions;
      expect(filtered.length, 1);
      expect(filtered.first.sessionId, 1);
    });

    test('4. setExerciseFilter()：指定種目を含むセッションのみ表示される', () async {
      final s1 = makeSession(id: 1, date: DateTime(2026, 6, 1));
      final s2 = makeSession(id: 2, date: DateTime(2026, 6, 2));
      final set1 = makeSet(setId: 1, sessionId: 1, exerciseId: 10);
      final set2 = makeSet(setId: 2, sessionId: 2, exerciseId: 20);

      when(mockSessionRepo.findAll()).thenAnswer((_) async => [s1, s2]);
      when(mockSetRepo.findAll()).thenAnswer((_) async => [set1, set2]);
      when(mockExerciseRepo.findAll()).thenAnswer((_) async => []);

      container.listen(workoutListProvider, (_, _) {});
      await waitForFetch();

      notifier().setExerciseFilter(10);

      final filtered = currentState().filteredSessions;
      expect(filtered.length, 1);
      expect(filtered.first.sessionId, 1);
    });

    test('5. 月フィルター＋種目フィルター同時適用：AND条件で絞り込まれる', () async {
      final s1 = makeSession(id: 1, date: DateTime(2026, 6, 1));
      final s2 = makeSession(id: 2, date: DateTime(2026, 5, 1));
      final s3 = makeSession(id: 3, date: DateTime(2026, 6, 2));
      final set1 = makeSet(setId: 1, sessionId: 1, exerciseId: 10);
      final set2 = makeSet(setId: 2, sessionId: 2, exerciseId: 10);
      final set3 = makeSet(setId: 3, sessionId: 3, exerciseId: 20);

      when(mockSessionRepo.findAll()).thenAnswer((_) async => [s1, s2, s3]);
      when(mockSetRepo.findAll()).thenAnswer((_) async => [set1, set2, set3]);
      when(mockExerciseRepo.findAll()).thenAnswer((_) async => []);

      container.listen(workoutListProvider, (_, _) {});
      await waitForFetch();

      notifier().setMonthFilter(202606);
      notifier().setExerciseFilter(10);

      // 6月かつexerciseId=10を含む → s1のみ
      final filtered = currentState().filteredSessions;
      expect(filtered.length, 1);
      expect(filtered.first.sessionId, 1);
    });

    test('6. フィルターリセット：全件表示に戻る', () async {
      final s1 = makeSession(id: 1, date: DateTime(2026, 6, 1));
      final s2 = makeSession(id: 2, date: DateTime(2026, 5, 1));

      when(mockSessionRepo.findAll()).thenAnswer((_) async => [s1, s2]);
      when(mockSetRepo.findAll()).thenAnswer((_) async => []);
      when(mockExerciseRepo.findAll()).thenAnswer((_) async => []);

      container.listen(workoutListProvider, (_, _) {});
      await waitForFetch();

      notifier().setMonthFilter(202606);
      expect(currentState().filteredSessions.length, 1);

      notifier().setMonthFilter(null);
      expect(currentState().filteredSessions.length, 2);
    });

    test('7. 0件時：sessionsが空リストになりエラーにならない', () async {
      when(mockSessionRepo.findAll()).thenAnswer((_) async => []);
      when(mockSetRepo.findAll()).thenAnswer((_) async => []);
      when(mockExerciseRepo.findAll()).thenAnswer((_) async => []);

      container.listen(workoutListProvider, (_, _) {});
      await waitForFetch();

      expect(currentState().filteredSessions, isEmpty);
    });

    test('8. availableMonths：セッションの月一覧が新しい順で返される', () async {
      final s1 = makeSession(id: 1, date: DateTime(2026, 6, 1));
      final s2 = makeSession(id: 2, date: DateTime(2026, 5, 1));
      final s3 = makeSession(id: 3, date: DateTime(2026, 6, 15));

      when(mockSessionRepo.findAll()).thenAnswer((_) async => [s1, s2, s3]);
      when(mockSetRepo.findAll()).thenAnswer((_) async => []);
      when(mockExerciseRepo.findAll()).thenAnswer((_) async => []);

      container.listen(workoutListProvider, (_, _) {});
      await waitForFetch();

      final months = currentState().availableMonths;
      expect(months, [202606, 202605]); // 新しい順・重複なし
    });
  });
}
