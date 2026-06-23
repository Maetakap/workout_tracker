import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:workout_tracker/data/database/app_database.dart';
import 'package:workout_tracker/features/workout_list/workout_list_notifier.dart';
import 'package:workout_tracker/features/workout_list/workout_list_screen.dart';
import 'package:workout_tracker/features/workout_list/workout_list_state.dart';

void main() {
  WorkoutSession makeSession({required int id, required DateTime date}) {
    return WorkoutSession(
      sessionId: id,
      date: date,
      focusLevel: 3,
      memo: null,
      createdAt: DateTime(2026, 1, 1),
    );
  }

  WorkoutSet makeSet({
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

  ExerciseMaster makeExercise({required int id, required String name}) {
    return ExerciseMaster(
      exerciseId: id,
      name: name,
      sortOrder: 0,
      createdAt: DateTime(2026, 1, 1),
    );
  }

  /// 指定状態でWorkoutListScreenをpumpする
  Future<void> pumpListScreen(
    WidgetTester tester, {
    required WorkoutListState state,
  }) async {
    final router = GoRouter(
      initialLocation: '/list',
      routes: [
        GoRoute(path: '/list', builder: (_, _) => const WorkoutListScreen()),
        GoRoute(path: '/list/detail/:id', builder: (_, _) => const Scaffold()),
        GoRoute(
          path: '/list/detail/:id/edit',
          builder: (_, _) => const Scaffold(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          workoutListProvider.overrideWith(
            () => _FakeWorkoutListNotifier(state),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
  }

  group('WorkoutListScreen', () {
    testWidgets('1. セッション一覧が表示される', (tester) async {
      final state = WorkoutListState(
        sessions: [
          makeSession(id: 1, date: DateTime(2026, 6, 1)),
          makeSession(id: 2, date: DateTime(2026, 6, 2)),
        ],
        sets: [
          makeSet(setId: 1, sessionId: 1, exerciseId: 10),
          makeSet(setId: 2, sessionId: 2, exerciseId: 10),
        ],
        exercises: [makeExercise(id: 10, name: 'ベンチプレス')],
      );

      await pumpListScreen(tester, state: state);

      expect(find.textContaining('2026/06/01'), findsOneWidget);
      expect(find.textContaining('2026/06/02'), findsOneWidget);
    });

    testWidgets('2. 0件時に空状態UIが表示される', (tester) async {
      await pumpListScreen(tester, state: const WorkoutListState());

      expect(find.text('記録がありません'), findsOneWidget);
    });

    testWidgets('3. セッションのサブタイトルに種目名が表示される', (tester) async {
      final state = WorkoutListState(
        sessions: [makeSession(id: 1, date: DateTime(2026, 6, 1))],
        sets: [makeSet(setId: 1, sessionId: 1, exerciseId: 10)],
        exercises: [makeExercise(id: 10, name: 'ベンチプレス')],
      );

      await pumpListScreen(tester, state: state);

      expect(find.textContaining('ベンチプレス'), findsOneWidget);
    });

    testWidgets('4. 月フィルター・種目フィルターのドロップダウンが表示される', (tester) async {
      final state = WorkoutListState(
        sessions: [makeSession(id: 1, date: DateTime(2026, 6, 1))],
        sets: [makeSet(setId: 1, sessionId: 1, exerciseId: 10)],
        exercises: [makeExercise(id: 10, name: 'ベンチプレス')],
      );

      await pumpListScreen(tester, state: state);

      expect(find.text('全期間'), findsOneWidget);
      expect(find.text('すべての種目'), findsOneWidget);
    });

    testWidgets('5. ローディング中はインジケーターが表示される', (tester) async {
      await pumpListScreen(
        tester,
        state: const WorkoutListState(isLoading: true),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('6. 月フィルターを開くと選択肢が表示される', (tester) async {
      final state = WorkoutListState(
        sessions: [makeSession(id: 1, date: DateTime(2026, 6, 1))],
        sets: [makeSet(setId: 1, sessionId: 1, exerciseId: 10)],
        exercises: [makeExercise(id: 10, name: 'ベンチプレス')],
      );

      await pumpListScreen(tester, state: state);

      // 月フィルターのドロップダウンをタップ
      await tester.tap(find.text('全期間'));
      await tester.pumpAndSettle();

      // 2026年06月の選択肢が表示される
      expect(find.text('2026年06月'), findsWidgets);
    });
  });
}

/// 指定状態を返すWorkoutListNotifier（テスト用）
class _FakeWorkoutListNotifier extends WorkoutListNotifier {
  _FakeWorkoutListNotifier(this._initialState);

  final WorkoutListState _initialState;

  @override
  WorkoutListState build() => _initialState;
}
