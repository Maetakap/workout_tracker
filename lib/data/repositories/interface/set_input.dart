/// セッション保存時のセット入力（sessionIdを含まないプレーン型）
class SetInput {
  final int exerciseId;
  final int setOrder;
  final double weightKg;
  final int reps;
  final int rir;

  const SetInput({
    required this.exerciseId,
    required this.setOrder,
    required this.weightKg,
    required this.reps,
    required this.rir,
  });

  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      'setOrder': setOrder,
      'weightKg': weightKg,
      'reps': reps,
      'rir': rir,
    };
  }
}
