import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../exercise_master/exercise_master_notifier.dart';
import '../shared/workout_widgets.dart';
import 'workout_input_notifier.dart';

class WorkoutInputScreen extends ConsumerWidget {
  const WorkoutInputScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workoutInputProvider);
    final notifier = ref.read(workoutInputProvider.notifier);
    final exercises = ref.watch(exerciseMasterProvider).exercises;

    return Scaffold(
      appBar: AppBar(title: const Text('トレーニング記録')),
      body: exercises.isEmpty
          ? const _NoExercisePrompt()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ...state.exerciseCards.asMap().entries.map((entry) {
                  return ExerciseCard(
                    key: ValueKey(entry.key),
                    cardIndex: entry.key,
                    card: entry.value,
                    exercises: exercises,
                    canRemove: state.exerciseCards.length > 1,
                    notifier: notifier,
                  );
                }),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: notifier.addExerciseCard,
                  icon: const Icon(Icons.add),
                  label: const Text('種目を追加'),
                ),
                const SizedBox(height: 16),
                const SectionLabel('没頭度'),
                StarInput(
                  value: state.focusLevel,
                  onChanged: notifier.setFocusLevel,
                ),
                const SizedBox(height: 16),
                const SectionLabel('メモ（任意）'),
                TextField(
                  maxLength: 200,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: '例）肘を腰に差す感じでやると良い',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: notifier.setMemo,
                ),
                const SizedBox(height: 8),
              ],
            ),
      bottomNavigationBar: SaveBar(
        canSave: state.canSave() && !state.isSaving,
        isSaving: state.isSaving,
        onSave: () async {
          await notifier.saveSession();
          if (context.mounted) context.go('/list');
        },
      ),
    );
  }
}

class _NoExercisePrompt extends StatelessWidget {
  const _NoExercisePrompt();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('種目が登録されていません'),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.go('/exercise-master'),
            child: const Text('種目を追加する'),
          ),
        ],
      ),
    );
  }
}
