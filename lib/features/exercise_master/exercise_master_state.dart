import '../../data/database/app_database.dart';

class ExerciseMasterState {
  final List<ExerciseMaster> exercises;
  final bool isLoading;

  const ExerciseMasterState({
    this.exercises = const [],
    this.isLoading = false,
  });

  ExerciseMasterState copyWith({
    List<ExerciseMaster>? exercises,
    bool? isLoading,
  }) {
    return ExerciseMasterState(
      exercises: exercises ?? this.exercises,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
