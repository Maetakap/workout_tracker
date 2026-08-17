import 'package:flutter/widgets.dart';

import '../shared/workout_math.dart';

class SetRowState {
  final String id;
  final double? weightKg;
  final int? reps;
  final int? rir;

  SetRowState({String? id, this.weightKg, this.reps, this.rir})
    : id = id ?? UniqueKey().toString();

  SetRowState copyWith({double? weightKg, int? reps, int? rir}) {
    return SetRowState(
      id: id,
      weightKg: weightKg ?? this.weightKg,
      reps: reps ?? this.reps,
      rir: rir ?? this.rir,
    );
  }
}

class ExerciseCardState {
  final String id;
  final int? exerciseId;
  final List<SetRowState> sets;

  ExerciseCardState({String? id, this.exerciseId, List<SetRowState>? sets})
    : id = id ?? UniqueKey().toString(),
      sets = sets ?? [SetRowState()];

  ExerciseCardState copyWith({int? exerciseId, List<SetRowState>? sets}) {
    return ExerciseCardState(
      id: id,
      exerciseId: exerciseId ?? this.exerciseId,
      sets: sets ?? this.sets,
    );
  }

  double totalVolume() =>
      sumVolume(sets.map((s) => (s.weightKg ?? 0, s.reps ?? 0)));
}

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

class WorkoutInputState {
  final List<ExerciseCardState> exerciseCards;
  final int? focusLevel;
  final String memo;
  final DateTime date;
  final bool isSaving;

  WorkoutInputState({
    List<ExerciseCardState>? exerciseCards,
    this.focusLevel,
    this.memo = '',
    DateTime? date,
    this.isSaving = false,
  }) : exerciseCards = exerciseCards ?? [ExerciseCardState()],
       date = date ?? _today();

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

  WorkoutInputState copyWith({
    List<ExerciseCardState>? exerciseCards,
    int? focusLevel,
    String? memo,
    DateTime? date,
    bool? isSaving,
    bool clearFocusLevel = false,
  }) {
    return WorkoutInputState(
      exerciseCards: exerciseCards ?? this.exerciseCards,
      focusLevel: clearFocusLevel ? null : focusLevel ?? this.focusLevel,
      memo: memo ?? this.memo,
      date: date ?? this.date,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}
