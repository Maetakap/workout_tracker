import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/app_database.dart';
import '../../data/providers.dart';
import '../workout_list/workout_list_notifier.dart';
import 'workout_input_state.dart';

class WorkoutInputNotifier extends Notifier<WorkoutInputState> {
  @override
  WorkoutInputState build() => WorkoutInputState();

  void addExerciseCard() {
    state = state.copyWith(
      exerciseCards: [...state.exerciseCards, ExerciseCardState()],
    );
  }

  void removeExerciseCard(int cardIndex) {
    if (state.exerciseCards.length <= 1) return;
    final list = [...state.exerciseCards]..removeAt(cardIndex);
    state = state.copyWith(exerciseCards: list);
  }

  void setExerciseId(int cardIndex, int exerciseId) {
    final list = [...state.exerciseCards];
    list[cardIndex] = list[cardIndex].copyWith(exerciseId: exerciseId);
    state = state.copyWith(exerciseCards: list);
  }

  void addSet(int cardIndex) {
    final list = [...state.exerciseCards];
    final card = list[cardIndex];
    final lastSet = card.sets.last;
    // kgのみコピー、REP・RIRは空
    final newSet = SetRowState(weightKg: lastSet.weightKg);
    list[cardIndex] = card.copyWith(sets: [...card.sets, newSet]);
    state = state.copyWith(exerciseCards: list);
  }

  void removeSet(int cardIndex, int setIndex) {
    final card = state.exerciseCards[cardIndex];
    if (card.sets.length <= 1) return;
    final list = [...state.exerciseCards];
    final sets = [...card.sets]..removeAt(setIndex);
    list[cardIndex] = card.copyWith(sets: sets);
    state = state.copyWith(exerciseCards: list);
  }

  void updateWeight(int cardIndex, int setIndex, double? value) {
    _updateSet(cardIndex, setIndex, (s) => s.copyWith(weightKg: value));
  }

  void updateReps(int cardIndex, int setIndex, int? value) {
    _updateSet(cardIndex, setIndex, (s) => s.copyWith(reps: value));
  }

  void updateRir(int cardIndex, int setIndex, int? value) {
    _updateSet(cardIndex, setIndex, (s) => s.copyWith(rir: value));
  }

  void _updateSet(
    int cardIndex,
    int setIndex,
    SetRowState Function(SetRowState) update,
  ) {
    final cards = [...state.exerciseCards];
    final sets = [...cards[cardIndex].sets];
    sets[setIndex] = update(sets[setIndex]);
    cards[cardIndex] = cards[cardIndex].copyWith(sets: sets);
    state = state.copyWith(exerciseCards: cards);
  }

  void setFocusLevel(int level) {
    state = state.copyWith(focusLevel: level);
  }

  void setMemo(String memo) {
    state = state.copyWith(memo: memo);
  }

  Future<void> saveSession() async {
    if (!state.canSave()) return;
    state = state.copyWith(isSaving: true);

    try {
      final sessionRepo = ref.read(workoutSessionRepositoryProvider);
      final setRepo = ref.read(workoutSetRepositoryProvider);

      // セッション保存
      final sessionId = await sessionRepo.insert(
        date: DateTime.now(),
        focusLevel: state.focusLevel!,
        memo: state.memo.isEmpty ? null : state.memo,
      );

      // 全セットをsetOrderの通し番号で保存
      int setOrder = 0;
      final sets = <WorkoutSetsCompanion>[];
      for (final card in state.exerciseCards) {
        for (final set in card.sets) {
          sets.add(
            WorkoutSetsCompanion.insert(
              sessionId: sessionId,
              exerciseId: card.exerciseId!,
              setOrder: setOrder++,
              weightKg: set.weightKg!,
              reps: set.reps!,
              rir: set.rir!,
              createdAt: DateTime.now(),
            ),
          );
        }
      }
      await setRepo.insertAll(sets);

      ref.invalidate(workoutListProvider);
      // 入力状態をリセット
      state = WorkoutInputState();
    } catch (e, st) {
      debugPrint('saveSession error: $e');
      debugPrint('$st');
      state = state.copyWith(isSaving: false);
      rethrow;
    }
  }
}

final workoutInputProvider =
    NotifierProvider<WorkoutInputNotifier, WorkoutInputState>(
      WorkoutInputNotifier.new,
    );
