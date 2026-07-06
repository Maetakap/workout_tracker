import '../../data/repositories/interface/set_input.dart';
import '../workout_input/workout_input_state.dart';

/// ExerciseCard群を、setOrderを通し番号で振ったSetInputのリストに変換する。
/// 新規保存・編集保存で共通利用する。
List<SetInput> buildSetInputs(List<ExerciseCardState> cards) {
  int setOrder = 0;
  final sets = <SetInput>[];
  for (final card in cards) {
    for (final set in card.sets) {
      sets.add(
        SetInput(
          exerciseId: card.exerciseId!,
          setOrder: setOrder++,
          weightKg: set.weightKg!,
          reps: set.reps!,
          rir: set.rir!,
        ),
      );
    }
  }
  return sets;
}
