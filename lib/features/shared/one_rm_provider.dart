// lib/features/shared/one_rm_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers.dart';
import 'workout_math.dart';

/// 全種目の過去最高推定1RMを返す（exerciseId → 推定1RM）。
/// 記録がない種目はキー自体が存在しない（参照側で null 扱い）。
final exerciseOneRmProvider = FutureProvider<Map<int, double?>>((ref) async {
  final sets = await ref.watch(workoutSetRepositoryProvider).findAll();

  final result = <int, double?>{};
  for (final set in sets) {
    final oneRm = estimate1RM(set.weightKg, set.reps);
    final current = result[set.exerciseId];
    if (current == null || oneRm > current) {
      result[set.exerciseId] = oneRm;
    }
  }
  return result;
});
