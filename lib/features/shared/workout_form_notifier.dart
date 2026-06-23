/// 入力・編集画面のNotifierが共通で持つ操作の抽象インターフェース
abstract interface class WorkoutFormNotifier {
  void addExerciseCard();
  void removeExerciseCard(int cardIndex);
  void setExerciseId(int cardIndex, int exerciseId);
  void addSet(int cardIndex);
  void removeSet(int cardIndex, int setIndex);
  void updateWeight(int cardIndex, int setIndex, double? value);
  void updateReps(int cardIndex, int setIndex, int? value);
  void updateRir(int cardIndex, int setIndex, int? value);
}
