import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers.dart';
import '../exercise_master/exercise_master_notifier.dart';
import 'workout_list_state.dart';

class WorkoutListNotifier extends Notifier<WorkoutListState> {
  @override
  WorkoutListState build() {
    // 種目マスターが変更されたら再取得（種目名の変更を反映）
    ref.listen(exerciseMasterProvider, (_, _) => _fetchAll());
    Future.microtask(() => _fetchAll());
    return const WorkoutListState();
  }

  Future<void> _fetchAll() async {
    state = state.copyWith(isLoading: true);
    final sessions = await ref.read(workoutSessionRepositoryProvider).findAll();
    final sets = await ref.read(workoutSetRepositoryProvider).findAll();
    final exercises = await ref
        .read(exerciseMasterRepositoryProvider)
        .findAll();
    state = state.copyWith(
      sessions: sessions,
      sets: sets,
      exercises: exercises,
      isLoading: false,
    );
  }

  void setMonthFilter(int? yyyyMM) {
    state = yyyyMM == null
        ? state.copyWith(clearMonth: true)
        : state.copyWith(selectedMonth: yyyyMM);
  }

  void setExerciseFilter(int? exerciseId) {
    state = exerciseId == null
        ? state.copyWith(clearExercise: true)
        : state.copyWith(selectedExerciseId: exerciseId);
  }
}

final workoutListProvider =
    NotifierProvider<WorkoutListNotifier, WorkoutListState>(
      WorkoutListNotifier.new,
    );
