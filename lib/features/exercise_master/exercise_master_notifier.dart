import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers.dart';
import 'exercise_master_state.dart';

class ExerciseMasterNotifier extends Notifier<ExerciseMasterState> {
  @override
  ExerciseMasterState build() {
    Future.microtask(() => _fetchExercises());
    return const ExerciseMasterState();
  }

  Future<void> _fetchExercises() async {
    state = state.copyWith(isLoading: true);
    final exercises = await ref
        .read(exerciseMasterRepositoryProvider)
        .findAll();
    state = state.copyWith(exercises: exercises, isLoading: false);
  }

  Future<void> addExercise(String name) async {
    final nextOrder = state.exercises.length;
    await ref.read(exerciseMasterRepositoryProvider).insert(name, nextOrder);
    await _fetchExercises();
  }

  Future<void> updateName(int exerciseId, String name) async {
    await ref
        .read(exerciseMasterRepositoryProvider)
        .updateName(exerciseId, name);
    await _fetchExercises();
  }

  Future<void> deleteExercise(int exerciseId) async {
    await ref.read(exerciseMasterRepositoryProvider).delete(exerciseId);
    await _fetchExercises();
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    final list = [...state.exercises];
    if (newIndex > oldIndex) newIndex--;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    state = state.copyWith(exercises: list);
    await ref.read(exerciseMasterRepositoryProvider).updateSortOrders(list);
  }
}

final exerciseMasterProvider =
    NotifierProvider<ExerciseMasterNotifier, ExerciseMasterState>(
      ExerciseMasterNotifier.new,
    );
