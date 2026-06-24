import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/database/app_database.dart';
import '../exercise_master/exercise_master_notifier.dart';
import '../shared/workout_widgets.dart';
import 'workout_edit_notifier.dart';
import 'workout_edit_state.dart';

class WorkoutEditScreen extends ConsumerWidget {
  const WorkoutEditScreen({super.key, required this.sessionId});

  final int sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editAsync = ref.watch(workoutEditProvider(sessionId));
    final exercises = ref.watch(exerciseMasterProvider).exercises;

    return Scaffold(
      appBar: AppBar(title: const Text('編集')),
      body: editAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('エラー: $e')),
        data: (editState) {
          if (editState.session == null) {
            return const Center(child: Text('データが見つかりません'));
          }
          return _EditForm(
            sessionId: sessionId,
            editState: editState,
            exercises: exercises,
          );
        },
      ),
    );
  }
}

class _EditForm extends ConsumerStatefulWidget {
  const _EditForm({
    required this.sessionId,
    required this.editState,
    required this.exercises,
  });

  final int sessionId;
  final WorkoutEditState editState;
  final List<ExerciseMaster> exercises;

  @override
  ConsumerState<_EditForm> createState() => _EditFormState();
}

class _EditFormState extends ConsumerState<_EditForm> {
  late final TextEditingController _memoController;

  @override
  void initState() {
    super.initState();
    _memoController = TextEditingController(text: widget.editState.memo);
  }

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(workoutEditProvider(widget.sessionId).notifier);
    final editState = widget.editState;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...editState.exerciseCards.asMap().entries.map((entry) {
            return ExerciseCard(
              key: ValueKey(entry.value.id),
              cardIndex: entry.key,
              card: entry.value,
              exercises: widget.exercises,
              canRemove: editState.exerciseCards.length > 1,
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
            value: editState.focusLevel,
            onChanged: notifier.setFocusLevel,
          ),
          const SizedBox(height: 16),
          const SectionLabel('メモ（任意）'),
          TextField(
            controller: _memoController,
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
        canSave: editState.canSave() && !editState.isSaving,
        isSaving: editState.isSaving,
        onSave: () async {
          final success = await notifier.save();
          if (success && context.mounted) context.pop();
        },
      ),
    );
  }
}
