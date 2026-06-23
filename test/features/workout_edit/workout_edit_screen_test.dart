import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:workout_tracker/data/database/app_database.dart';
import 'package:workout_tracker/features/exercise_master/exercise_master_notifier.dart';
import 'package:workout_tracker/features/exercise_master/exercise_master_state.dart';
import 'package:workout_tracker/features/workout_edit/workout_edit_notifier.dart';
import 'package:workout_tracker/features/workout_edit/workout_edit_screen.dart';
import 'package:workout_tracker/features/workout_edit/workout_edit_state.dart';
import 'package:workout_tracker/features/workout_input/workout_input_state.dart';

void main() {
  ExerciseMaster makeExercise({required int id, required String name}) {
    return ExerciseMaster(
      exerciseId: id,
      name: name,
      sortOrder: 0,
      createdAt: DateTime(2026, 1, 1),
    );
  }

  WorkoutSession makeSession() {
    return WorkoutSession(
      sessionId: 1,
      date: DateTime(2026, 6, 1),
      focusLevel: 3,
      memo: 'テストメモ',
      createdAt: DateTime(2026, 6, 1),
    );
  }

  /// 指定状態でWorkoutEditScreenをpumpする
  Future<void> pumpEditScreen(
    WidgetTester tester, {
    required WorkoutEditState editState,
    required List<ExerciseMaster> exercises,
  }) async {
    final router = GoRouter(
      initialLocation: '/list/detail/1/edit',
      routes: [
        GoRoute(
          path: '/list/detail/1/edit',
          builder: (_, _) => const WorkoutEditScreen(sessionId: 1),
        ),
        GoRoute(path: '/list/detail/1', builder: (_, _) => const Scaffold()),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          workoutEditProvider.overrideWith(
            () => _FakeWorkoutEditNotifier(editState),
          ),
          exerciseMasterProvider.overrideWith(
            () => _FakeExerciseMasterNotifier(
              ExerciseMasterState(exercises: exercises),
            ),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
  }

  group('WorkoutEditScreen', () {
    testWidgets('1. 既存データが初期表示される', (tester) async {
      final state = WorkoutEditState(
        session: makeSession(),
        exerciseCards: [
          ExerciseCardState(
            exerciseId: 1,
            sets: [SetRowState(weightKg: 80.0, reps: 5, rir: 1)],
          ),
        ],
        focusLevel: 3,
        memo: 'テストメモ',
      );

      await pumpEditScreen(
        tester,
        editState: state,
        exercises: [makeExercise(id: 1, name: 'ベンチプレス')],
      );

      // 種目名・重量・回数・メモが表示される
      expect(find.text('ベンチプレス'), findsOneWidget);
      expect(find.text('80'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('テストメモ'), findsOneWidget);
    });

    testWidgets('2. 保存ボタンが表示される', (tester) async {
      final state = WorkoutEditState(
        session: makeSession(),
        exerciseCards: [
          ExerciseCardState(
            exerciseId: 1,
            sets: [SetRowState(weightKg: 80.0, reps: 5, rir: 1)],
          ),
        ],
        focusLevel: 3,
      );

      await pumpEditScreen(
        tester,
        editState: state,
        exercises: [makeExercise(id: 1, name: 'ベンチプレス')],
      );

      expect(find.text('保存'), findsOneWidget);
    });

    testWidgets('3. 全項目入力済みのとき保存ボタンが活性', (tester) async {
      final state = WorkoutEditState(
        session: makeSession(),
        exerciseCards: [
          ExerciseCardState(
            exerciseId: 1,
            sets: [SetRowState(weightKg: 80.0, reps: 5, rir: 1)],
          ),
        ],
        focusLevel: 3,
      );

      await pumpEditScreen(
        tester,
        editState: state,
        exercises: [makeExercise(id: 1, name: 'ベンチプレス')],
      );

      final saveButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, '保存'),
      );
      expect(saveButton.onPressed, isNotNull);
    });

    testWidgets('4. データが見つからない場合のメッセージ', (tester) async {
      await pumpEditScreen(
        tester,
        editState: const WorkoutEditState(session: null),
        exercises: [],
      );

      expect(find.text('データが見つかりません'), findsOneWidget);
    });

    testWidgets('5. 没頭度ラベルが表示される', (tester) async {
      final state = WorkoutEditState(
        session: makeSession(),
        exerciseCards: [
          ExerciseCardState(
            exerciseId: 1,
            sets: [SetRowState(weightKg: 80.0, reps: 5, rir: 1)],
          ),
        ],
        focusLevel: 3,
      );

      await pumpEditScreen(
        tester,
        editState: state,
        exercises: [makeExercise(id: 1, name: 'ベンチプレス')],
      );

      expect(find.text('没頭度'), findsOneWidget);
      expect(find.text('メモ（任意）'), findsOneWidget);
    });
  });
}

/// 指定状態を返すWorkoutEditNotifier（テスト用）
class _FakeWorkoutEditNotifier extends WorkoutEditNotifier {
  _FakeWorkoutEditNotifier(this._initialState);

  final WorkoutEditState _initialState;

  @override
  Future<WorkoutEditState> build(int arg) async => _initialState;
}

/// 指定状態を返すExerciseMasterNotifier（テスト用）
class _FakeExerciseMasterNotifier extends ExerciseMasterNotifier {
  _FakeExerciseMasterNotifier(this._initialState);

  final ExerciseMasterState _initialState;

  @override
  ExerciseMasterState build() => _initialState;
}
