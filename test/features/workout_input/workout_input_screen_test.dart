import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:workout_tracker/data/database/app_database.dart';
import 'package:workout_tracker/features/exercise_master/exercise_master_notifier.dart';
import 'package:workout_tracker/features/exercise_master/exercise_master_state.dart';
import 'package:workout_tracker/features/workout_input/workout_input_notifier.dart';
import 'package:workout_tracker/features/workout_input/workout_input_screen.dart';
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

  /// 指定状態でWorkoutInputScreenをpumpする
  Future<void> pumpInputScreen(
    WidgetTester tester, {
    required WorkoutInputState inputState,
    required List<ExerciseMaster> exercises,
  }) async {
    final router = GoRouter(
      initialLocation: '/input',
      routes: [
        GoRoute(path: '/input', builder: (_, _) => const WorkoutInputScreen()),
        GoRoute(path: '/list', builder: (_, _) => const Scaffold()),
        GoRoute(path: '/exercise-master', builder: (_, _) => const Scaffold()),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          workoutInputProvider.overrideWith(
            () => _FakeWorkoutInputNotifier(inputState),
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

  group('WorkoutInputScreen', () {
    testWidgets('1. 種目未登録時に「種目を追加する」プロンプトが表示される', (tester) async {
      await pumpInputScreen(
        tester,
        inputState: WorkoutInputState(),
        exercises: [],
      );

      expect(find.text('種目が登録されていません'), findsOneWidget);
      expect(find.text('種目を追加する'), findsOneWidget);
    });

    testWidgets('2. 種目登録済み時に入力フォームが表示される', (tester) async {
      await pumpInputScreen(
        tester,
        inputState: WorkoutInputState(),
        exercises: [makeExercise(id: 1, name: 'ベンチプレス')],
      );

      // 種目カードのドロップダウン・メモ欄・保存バーが表示される
      expect(find.text('種目を選択'), findsOneWidget);
      expect(find.text('没頭度'), findsOneWidget);
      expect(find.text('メモ（任意）'), findsOneWidget);
      expect(find.text('保存'), findsOneWidget);
    });

    testWidgets('3. canSave=falseのとき保存ボタンが非活性', (tester) async {
      await pumpInputScreen(
        tester,
        inputState: WorkoutInputState(), // 未入力＝canSave false
        exercises: [makeExercise(id: 1, name: 'ベンチプレス')],
      );

      final saveButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, '保存'),
      );
      expect(saveButton.onPressed, isNull); // 非活性
    });

    testWidgets('4. 全項目入力済みのとき保存ボタンが活性', (tester) async {
      final state = WorkoutInputState(
        exerciseCards: [
          ExerciseCardState(
            exerciseId: 1,
            sets: [SetRowState(weightKg: 60.0, reps: 10, rir: 2)],
          ),
        ],
        focusLevel: 3,
      );

      await pumpInputScreen(
        tester,
        inputState: state,
        exercises: [makeExercise(id: 1, name: 'ベンチプレス')],
      );

      final saveButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, '保存'),
      );
      expect(saveButton.onPressed, isNotNull); // 活性
    });

    testWidgets('5. 「種目を追加」ボタンが表示される', (tester) async {
      await pumpInputScreen(
        tester,
        inputState: WorkoutInputState(),
        exercises: [makeExercise(id: 1, name: 'ベンチプレス')],
      );

      expect(find.text('種目を追加'), findsOneWidget);
    });

    testWidgets('6. 保存中はローディングインジケーターが表示される', (tester) async {
      final state = WorkoutInputState(
        exerciseCards: [
          ExerciseCardState(
            exerciseId: 1,
            sets: [SetRowState(weightKg: 60.0, reps: 10, rir: 2)],
          ),
        ],
        focusLevel: 3,
        isSaving: true,
      );

      await pumpInputScreen(
        tester,
        inputState: state,
        exercises: [makeExercise(id: 1, name: 'ベンチプレス')],
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}

/// 指定状態を返すWorkoutInputNotifier（テスト用）
class _FakeWorkoutInputNotifier extends WorkoutInputNotifier {
  _FakeWorkoutInputNotifier(this._initialState);

  final WorkoutInputState _initialState;

  @override
  WorkoutInputState build() => _initialState;
}

/// 指定状態を返すExerciseMasterNotifier（テスト用）
class _FakeExerciseMasterNotifier extends ExerciseMasterNotifier {
  _FakeExerciseMasterNotifier(this._initialState);

  final ExerciseMasterState _initialState;

  @override
  ExerciseMasterState build() => _initialState;
}
