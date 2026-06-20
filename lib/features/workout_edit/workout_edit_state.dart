import '../../data/database/app_database.dart';
import '../workout_input/workout_input_state.dart';

class WorkoutEditState {
  final WorkoutSession? session;
  final List<ExerciseCardState> exerciseCards;
  final int? focusLevel;
  final String memo;
  final bool isSaving;

  const WorkoutEditState({
    this.session,
    this.exerciseCards = const [],
    this.focusLevel,
    this.memo = '',
    this.isSaving = false,
  });

  bool canSave() {
    if (focusLevel == null) return false;
    if (exerciseCards.isEmpty) return false;
    for (final card in exerciseCards) {
      if (card.exerciseId == null) return false;
      if (card.sets.isEmpty) return false;
      for (final set in card.sets) {
        if (set.weightKg == null || set.reps == null || set.rir == null) {
          return false;
        }
      }
    }
    return true;
  }

  WorkoutEditState copyWith({
    WorkoutSession? session,
    List<ExerciseCardState>? exerciseCards,
    int? focusLevel,
    String? memo,
    bool? isSaving,
  }) {
    return WorkoutEditState(
      session: session ?? this.session,
      exerciseCards: exerciseCards ?? this.exerciseCards,
      focusLevel: focusLevel ?? this.focusLevel,
      memo: memo ?? this.memo,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}
