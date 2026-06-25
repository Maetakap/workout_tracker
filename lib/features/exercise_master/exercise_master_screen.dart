import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../shared/confirm_dialog.dart';
import '../shared/swipeable_list_item.dart';
import '../shared/workout_math.dart';
import '../shared/one_rm_provider.dart';
import 'exercise_master_notifier.dart';

class ExerciseMasterScreen extends ConsumerWidget {
  const ExerciseMasterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final oneRmAsync = ref.watch(exerciseOneRmProvider);
    final oneRmMap = oneRmAsync.valueOrNull ?? const <int, double?>{};
    final state = ref.watch(exerciseMasterProvider);
    final notifier = ref.read(exerciseMasterProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('種目管理')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.exercises.isEmpty
          ? const Center(child: Text('種目がありません'))
          : ReorderableListView.builder(
              itemCount: state.exercises.length,
              onReorder: (oldIndex, newIndex) =>
                  notifier.reorder(oldIndex, newIndex),
              itemBuilder: (context, index) {
                final exercise = state.exercises[index];
                return SwipeableListItem(
                  key: ValueKey(exercise.exerciseId),
                  onDeleteConfirm: () => showConfirmDialog(
                    context,
                    title: '種目を削除',
                    content: 'この種目を削除しますか？\n記録済みのデータには影響しません。',
                  ),
                  onEdit: () => _showEditDialog(
                    context,
                    ref,
                    exercise.exerciseId,
                    exercise.name,
                  ),
                  onDeleted: () async {
                    await ref
                        .read(exerciseMasterProvider.notifier)
                        .deleteExercise(exercise.exerciseId);
                  },
                  child: ListTile(
                    key: ValueKey(exercise.exerciseId),
                    title: Text(exercise.name),
                    leading: ReorderableDragStartListener(
                      index: index,
                      child: const Icon(Icons.drag_handle),
                    ),
                    trailing: Text(
                      formatOneRm(oneRmMap[exercise.exerciseId]),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<String?> _showExerciseNameDialog(
    BuildContext context, {
    required String title,
    required String confirmLabel,
    String initialText = '',
  }) async {
    final controller = TextEditingController(text: initialText);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 30,
          decoration: const InputDecoration(hintText: '種目名'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );

    if (confirmed == true && controller.text.isNotEmpty) {
      return controller.text;
    }
    return null;
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final name = await _showExerciseNameDialog(
      context,
      title: '種目を追加',
      confirmLabel: '追加',
    );
    if (name != null) {
      await ref.read(exerciseMasterProvider.notifier).addExercise(name);
    }
  }

  Future<void> _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    int exerciseId,
    String currentName,
  ) async {
    final name = await _showExerciseNameDialog(
      context,
      title: '種目を編集',
      confirmLabel: '保存',
      initialText: currentName,
    );
    if (name != null) {
      await ref
          .read(exerciseMasterProvider.notifier)
          .updateName(exerciseId, name);
    }
  }
}
