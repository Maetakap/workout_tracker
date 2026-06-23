import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/features/workout_input/workout_input_state.dart';

void main() {
  group('WorkoutInputState - canSave()', () {
    /// 全項目入力済みの有効なSetRowStateを生成
    SetRowState validSet() => SetRowState(weightKg: 60.0, reps: 10, rir: 2);

    /// 有効なExerciseCardStateを生成
    ExerciseCardState validCard() =>
        ExerciseCardState(exerciseId: 1, sets: [validSet()]);

    test('1. 全未入力：falseを返す', () {
      final state = WorkoutInputState();
      expect(state.canSave(), false);
    });

    test('2. 種目未選択：falseを返す', () {
      final state = WorkoutInputState(
        exerciseCards: [
          ExerciseCardState(sets: [validSet()]),
        ],
        focusLevel: 3,
      );
      expect(state.canSave(), false);
    });

    test('3. セット0件：falseを返す', () {
      final state = WorkoutInputState(
        exerciseCards: [ExerciseCardState(exerciseId: 1, sets: [])],
        focusLevel: 3,
      );
      expect(state.canSave(), false);
    });

    test('4. weightKgがnull：falseを返す', () {
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

    test('5. repsがnull：falseを返す', () {
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

    test('6. rirがnull：falseを返す', () {
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

    test('7. focusLevelがnull：falseを返す', () {
      final state = WorkoutInputState(
        exerciseCards: [validCard()],
        focusLevel: null,
      );
      expect(state.canSave(), false);
    });

    test('8. 全入力済み：trueを返す', () {
      final state = WorkoutInputState(
        exerciseCards: [validCard()],
        focusLevel: 3,
      );
      expect(state.canSave(), true);
    });

    test('9. 複数カード・一部未入力：falseを返す', () {
      final state = WorkoutInputState(
        exerciseCards: [
          validCard(),
          ExerciseCardState(sets: [validSet()]), // exerciseId未選択
        ],
        focusLevel: 3,
      );
      expect(state.canSave(), false);
    });

    test('10. 複数カード・全入力済み：trueを返す', () {
      final state = WorkoutInputState(
        exerciseCards: [validCard(), validCard()],
        focusLevel: 5,
      );
      expect(state.canSave(), true);
    });
  });

  group('WorkoutInputState - copyWith()', () {
    test('11. focusLevelのみ変更・他は保持される', () {
      final original = WorkoutInputState(focusLevel: 3, memo: 'test');
      final copied = original.copyWith(focusLevel: 5);
      expect(copied.focusLevel, 5);
      expect(copied.memo, 'test');
    });

    test('12. memoのみ変更・他は保持される', () {
      final original = WorkoutInputState(focusLevel: 3, memo: 'before');
      final copied = original.copyWith(memo: 'after');
      expect(copied.memo, 'after');
      expect(copied.focusLevel, 3);
    });

    test('13. clearFocusLevel=true でfocusLevelがnullになる', () {
      final original = WorkoutInputState(focusLevel: 3);
      final copied = original.copyWith(clearFocusLevel: true);
      expect(copied.focusLevel, null);
    });
  });

  group('SetRowState - copyWith()', () {
    test('14. weightKgのみ変更・idは保持される', () {
      final original = SetRowState(weightKg: 60.0, reps: 10, rir: 2);
      final copied = original.copyWith(weightKg: 80.0);
      expect(copied.weightKg, 80.0);
      expect(copied.reps, 10);
      expect(copied.rir, 2);
      expect(copied.id, original.id); // idは変わらない
    });
  });
}
