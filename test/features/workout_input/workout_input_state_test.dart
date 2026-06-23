import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/features/workout_input/workout_input_state.dart';

void main() {
  // 全項目入力済みの有効なセットを生成
  SetRowState validSet() => SetRowState(weightKg: 60.0, reps: 10, rir: 2);

  // 全項目入力済みの有効なカードを生成
  ExerciseCardState validCard() =>
      ExerciseCardState(exerciseId: 1, sets: [validSet()]);

  group('WorkoutInputState.canSave()', () {
    test('全未入力ならfalse', () {
      expect(WorkoutInputState().canSave(), false);
    });

    test('種目未選択ならfalse', () {
      final state = WorkoutInputState(
        exerciseCards: [
          ExerciseCardState(sets: [validSet()]),
        ],
        focusLevel: 3,
      );
      expect(state.canSave(), false);
    });

    test('セット0件ならfalse', () {
      final state = WorkoutInputState(
        exerciseCards: [ExerciseCardState(exerciseId: 1, sets: [])],
        focusLevel: 3,
      );
      expect(state.canSave(), false);
    });

    test('weightKgがnullならfalse', () {
      final state = WorkoutInputState(
        exerciseCards: [
          ExerciseCardState(
            exerciseId: 1,
            sets: [SetRowState(reps: 10, rir: 2)],
          ),
        ],
        focusLevel: 3,
      );
      expect(state.canSave(), false);
    });

    test('repsがnullならfalse', () {
      final state = WorkoutInputState(
        exerciseCards: [
          ExerciseCardState(
            exerciseId: 1,
            sets: [SetRowState(weightKg: 60.0, rir: 2)],
          ),
        ],
        focusLevel: 3,
      );
      expect(state.canSave(), false);
    });

    test('rirがnullならfalse', () {
      final state = WorkoutInputState(
        exerciseCards: [
          ExerciseCardState(
            exerciseId: 1,
            sets: [SetRowState(weightKg: 60.0, reps: 10)],
          ),
        ],
        focusLevel: 3,
      );
      expect(state.canSave(), false);
    });

    test('focusLevelがnullならfalse', () {
      final state = WorkoutInputState(
        exerciseCards: [validCard()],
        focusLevel: null,
      );
      expect(state.canSave(), false);
    });

    test('全入力済みならtrue', () {
      final state = WorkoutInputState(
        exerciseCards: [validCard()],
        focusLevel: 3,
      );
      expect(state.canSave(), true);
    });

    test('複数カードで1つでも未入力ならfalse', () {
      final state = WorkoutInputState(
        exerciseCards: [
          validCard(),
          ExerciseCardState(sets: [validSet()]), // 種目未選択
        ],
        focusLevel: 3,
      );
      expect(state.canSave(), false);
    });

    test('複数カードすべて入力済みならtrue', () {
      final state = WorkoutInputState(
        exerciseCards: [validCard(), validCard()],
        focusLevel: 5,
      );
      expect(state.canSave(), true);
    });
  });

  group('WorkoutInputState.copyWith()', () {
    test('focusLevelのみ変更し他は保持', () {
      final original = WorkoutInputState(focusLevel: 3, memo: 'test');
      final copied = original.copyWith(focusLevel: 5);
      expect(copied.focusLevel, 5);
      expect(copied.memo, 'test');
    });

    test('memoのみ変更し他は保持', () {
      final original = WorkoutInputState(focusLevel: 3, memo: 'before');
      final copied = original.copyWith(memo: 'after');
      expect(copied.memo, 'after');
      expect(copied.focusLevel, 3);
    });

    test('clearFocusLevel=trueでfocusLevelがnullになる', () {
      final original = WorkoutInputState(focusLevel: 3);
      final copied = original.copyWith(clearFocusLevel: true);
      expect(copied.focusLevel, null);
    });
  });

  group('SetRowState.copyWith()', () {
    test('weightKgのみ変更しidは保持', () {
      final original = SetRowState(weightKg: 60.0, reps: 10, rir: 2);
      final copied = original.copyWith(weightKg: 80.0);
      expect(copied.weightKg, 80.0);
      expect(copied.reps, 10);
      expect(copied.rir, 2);
      expect(copied.id, original.id);
    });
  });
}
