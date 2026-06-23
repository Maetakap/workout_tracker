import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/app_database.dart';
import '../../data/providers.dart';
import '../shared/workout_form_notifier.dart';
import '../workout_detail/workout_detail_provider.dart';
import '../workout_input/workout_input_state.dart';
import '../workout_list/workout_list_notifier.dart';
import 'workout_edit_state.dart';

class WorkoutEditNotifier
    extends AutoDisposeFamilyAsyncNotifier<WorkoutEditState, int>
    implements WorkoutFormNotifier {
  @override
  Future<WorkoutEditState> build(int arg) async {
    final session = await ref
        .read(workoutSessionRepositoryProvider)
        .findById(arg);
    if (session == null) return const WorkoutEditState();

    final sets = await ref
        .read(workoutSetRepositoryProvider)
        .findBySessionId(arg);

    final groupMap = <int, List<WorkoutSet>>{};
    for (final set in sets) {
      groupMap.putIfAbsent(set.exerciseId, () => []).add(set);
    }

    final exerciseCards = groupMap.entries.map((entry) {
      final setRows = entry.value
          .map(
            (s) => SetRowState(weightKg: s.weightKg, reps: s.reps, rir: s.rir),
          )
          .toList();
      return ExerciseCardState(exerciseId: entry.key, sets: setRows);
    }).toList();

    return WorkoutEditState(
      session: session,
      exerciseCards: exerciseCards,
      focusLevel: session.focusLevel,
      memo: session.memo ?? '',
    );
  }

  @override
  void addExerciseCard() {
    final current = state.requireValue;
    state = AsyncData(
      current.copyWith(
        exerciseCards: [...current.exerciseCards, ExerciseCardState()],
      ),
    );
  }

  @override
  void removeExerciseCard(int cardIndex) {
    final current = state.requireValue;
    if (current.exerciseCards.length <= 1) return;
    final list = [...current.exerciseCards]..removeAt(cardIndex);
    state = AsyncData(current.copyWith(exerciseCards: list));
  }

  @override
  void setExerciseId(int cardIndex, int exerciseId) {
    final current = state.requireValue;
    final list = [...current.exerciseCards];
    list[cardIndex] = list[cardIndex].copyWith(exerciseId: exerciseId);
    state = AsyncData(current.copyWith(exerciseCards: list));
  }

  @override
  void addSet(int cardIndex) {
    final current = state.requireValue;
    final list = [...current.exerciseCards];
    final card = list[cardIndex];
    final lastSet = card.sets.last;
    final newSet = SetRowState(weightKg: lastSet.weightKg);
    list[cardIndex] = card.copyWith(sets: [...card.sets, newSet]);
    state = AsyncData(current.copyWith(exerciseCards: list));
  }

  @override
  void removeSet(int cardIndex, int setIndex) {
    final current = state.requireValue;
    final list = [...current.exerciseCards];
    final card = list[cardIndex];
    if (card.sets.length <= 1) return;
    final sets = [...card.sets]..removeAt(setIndex);
    list[cardIndex] = card.copyWith(sets: sets);
    state = AsyncData(current.copyWith(exerciseCards: list));
  }

  @override
  void updateWeight(int cardIndex, int setIndex, double? value) {
    _updateSet(cardIndex, setIndex, (s) => s.copyWith(weightKg: value));
  }

  @override
  void updateReps(int cardIndex, int setIndex, int? value) {
    _updateSet(cardIndex, setIndex, (s) => s.copyWith(reps: value));
  }

  @override
  void updateRir(int cardIndex, int setIndex, int? value) {
    _updateSet(cardIndex, setIndex, (s) => s.copyWith(rir: value));
  }

  void _updateSet(
    int cardIndex,
    int setIndex,
    SetRowState Function(SetRowState) update,
  ) {
    final current = state.requireValue;
    final cards = [...current.exerciseCards];
    final sets = [...cards[cardIndex].sets];
    sets[setIndex] = update(sets[setIndex]);
    cards[cardIndex] = cards[cardIndex].copyWith(sets: sets);
    state = AsyncData(current.copyWith(exerciseCards: cards));
  }

  void setFocusLevel(int level) {
    final current = state.requireValue;
    state = AsyncData(current.copyWith(focusLevel: level));
  }

  void setMemo(String memo) {
    final current = state.requireValue;
    state = AsyncData(current.copyWith(memo: memo));
  }

  Future<bool> save() async {
    final current = state.requireValue;
    if (!current.canSave()) return false;
    state = AsyncData(current.copyWith(isSaving: true));

    try {
      final sessionRepo = ref.read(workoutSessionRepositoryProvider);
      final setRepo = ref.read(workoutSetRepositoryProvider);

      await sessionRepo.update(
        sessionId: arg,
        date: current.session!.date,
        focusLevel: current.focusLevel!,
        memo: current.memo.isEmpty ? null : current.memo,
      );

      int setOrder = 0;
      final sets = <WorkoutSetsCompanion>[];
      for (final card in current.exerciseCards) {
        for (final set in card.sets) {
          sets.add(
            WorkoutSetsCompanion.insert(
              sessionId: arg,
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
      await setRepo.replaceAll(arg, sets);

      ref.invalidate(workoutListProvider);
      ref.invalidate(workoutDetailProvider(arg));

      state = AsyncData(current.copyWith(isSaving: false));
      return true;
    } catch (e) {
      debugPrint('save error: $e');
      state = AsyncData(current.copyWith(isSaving: false));
      return false;
    }
  }
}

final workoutEditProvider = AsyncNotifierProvider.autoDispose
    .family<WorkoutEditNotifier, WorkoutEditState, int>(
      WorkoutEditNotifier.new,
    );
