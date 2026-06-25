/// トレーニング関連の計算ロジックを集約するファイル。
/// 純粋関数のみを置く（DB・Riverpodに依存しない）。
library;

/// Epley式で推定1RM（1回挙上可能な最大重量の推定値）を計算する。
///
/// reps <= 1 のときは重量をそのまま返す
/// （Epley式では1回でも若干上乗せされてしまうため）。
double estimate1RM(double weight, int reps) {
  if (reps <= 1) return weight;
  return weight * (1 + reps / 30);
}

/// 推定1RMを表示用文字列にする。
/// 記録なし（null）は「1RM -- kg」、ありは「1RM 106.7 kg」。
String formatOneRm(double? value) {
  if (value == null) return '1RM -- kg';
  return '1RM ${value.toStringAsFixed(1)} kg';
}
