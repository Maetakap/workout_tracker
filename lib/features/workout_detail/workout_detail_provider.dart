import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/app_database.dart';
import '../../data/providers.dart';
import '../exercise_master/exercise_master_notifier.dart';

/// 1種目分のセット群をまとめたデータクラス
class ExerciseSetGroup {
  final String exerciseName;
  final List<WorkoutSet> sets;

  const ExerciseSetGroup({required this.exerciseName, required this.sets});
}

/// 詳細画面で使うデータをまとめたデータクラス
class WorkoutDetailData {
  final WorkoutSession session;
  final List<ExerciseSetGroup> groups;

  const WorkoutDetailData({required this.session, required this.groups});
}

final workoutDetailProvider = FutureProvider.family<WorkoutDetailData?, int>((
  ref,
  sessionId,
) async {
  final session = await ref
      .watch(workoutSessionRepositoryProvider)
      .findById(sessionId);
  if (session == null) return null;

  final sets = await ref
      .watch(workoutSetRepositoryProvider)
      .findBySessionId(sessionId);
  final exercises = ref.watch(exerciseMasterProvider).exercises;

  // setOrderでソート済みのsetsを種目ごとにグループ化（出現順を維持）
  final groupMap = <int, List<WorkoutSet>>{};
  for (final set in sets) {
    groupMap.putIfAbsent(set.exerciseId, () => []).add(set);
  }

  final groups = groupMap.entries.map((entry) {
    final exercise = exercises.firstWhere(
      (e) => e.exerciseId == entry.key,
      orElse: () => ExerciseMaster(
        exerciseId: -1,
        name: '(削除済み種目)',
        sortOrder: -1,
        createdAt: DateTime(0),
      ),
    );
    return ExerciseSetGroup(exerciseName: exercise.name, sets: entry.value);
  }).toList();

  return WorkoutDetailData(session: session, groups: groups);
});
