import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/database/app_database.dart';
import '../exercise_master/exercise_master_notifier.dart';
import '../workout_input/workout_input_state.dart';
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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...editState.exerciseCards.asMap().entries.map((entry) {
          return _ExerciseCard(
            key: ValueKey(entry.key),
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
        const _SectionLabel('没頭度'),
        _StarInput(
          value: editState.focusLevel,
          onChanged: notifier.setFocusLevel,
        ),
        const SizedBox(height: 16),
        const _SectionLabel('メモ（任意）'),
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
        const SizedBox(height: 16),
        FilledButton(
          onPressed: editState.canSave() && !editState.isSaving
              ? () async {
                  final success = await notifier.save();
                  if (success && context.mounted) {
                    context.pop();
                  }
                }
              : null,
          child: editState.isSaving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('保存'),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    super.key,
    required this.cardIndex,
    required this.card,
    required this.exercises,
    required this.canRemove,
    required this.notifier,
  });

  final int cardIndex;
  final ExerciseCardState card;
  final List<ExerciseMaster> exercises;
  final bool canRemove;
  final WorkoutEditNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    // ignore: deprecated_member_use
                    value: card.exerciseId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      hintText: '種目を選択',
                      hintStyle: TextStyle(color: Colors.grey),
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items: exercises
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.exerciseId,
                            child: Text(e.name),
                          ),
                        )
                        .toList(),
                    onChanged: (id) {
                      if (id != null) notifier.setExerciseId(cardIndex, id);
                    },
                  ),
                ),
                if (canRemove) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => notifier.removeExerciseCard(cardIndex),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                SizedBox(width: 32),
                Expanded(
                  child: Center(
                    child: Text(
                      'kg',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Center(
                    child: Text(
                      'REP',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Center(
                    child: Text(
                      'RIR',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ),
                SizedBox(width: 32),
              ],
            ),
            const SizedBox(height: 4),
            ...card.sets.asMap().entries.map((entry) {
              return _SetRow(
                key: ValueKey(entry.value.id),
                cardIndex: cardIndex,
                setIndex: entry.key,
                set: entry.value,
                canRemove: card.sets.length > 1,
                notifier: notifier,
              );
            }),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => notifier.addSet(cardIndex),
                icon: const Icon(Icons.add),
                label: const Text('セット追加'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetRow extends StatefulWidget {
  const _SetRow({
    super.key,
    required this.cardIndex,
    required this.setIndex,
    required this.set,
    required this.canRemove,
    required this.notifier,
  });

  final int cardIndex;
  final int setIndex;
  final SetRowState set;
  final bool canRemove;
  final WorkoutEditNotifier notifier;

  @override
  State<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<_SetRow> {
  late final TextEditingController _weightController;
  late final TextEditingController _repsController;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: _formatWeight(widget.set.weightKg),
    );
    _repsController = TextEditingController(
      text: widget.set.reps != null ? widget.set.reps.toString() : '',
    );
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  String _formatWeight(double? value) {
    if (value == null) return '';
    if (value == value.truncateToDouble()) return value.toInt().toString();
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              'S${widget.setIndex + 1}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 8,
                ),
              ),
              onChanged: (v) => widget.notifier.updateWeight(
                widget.cardIndex,
                widget.setIndex,
                double.tryParse(v),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _repsController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 8,
                ),
              ),
              onChanged: (v) => widget.notifier.updateReps(
                widget.cardIndex,
                widget.setIndex,
                int.tryParse(v),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<int>(
              // ignore: deprecated_member_use
              value: widget.set.rir,
              isDense: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
              ),
              items: List.generate(
                5,
                (i) => DropdownMenuItem(value: i, child: Text('$i')),
              ),
              onChanged: (v) => widget.notifier.updateRir(
                widget.cardIndex,
                widget.setIndex,
                v,
              ),
            ),
          ),
          SizedBox(
            width: 32,
            child: widget.canRemove
                ? IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () => widget.notifier.removeSet(
                      widget.cardIndex,
                      widget.setIndex,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _StarInput extends StatelessWidget {
  const _StarInput({required this.value, required this.onChanged});

  final int? value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final selected = value != null && i < value!;
        return IconButton(
          icon: Icon(
            selected ? Icons.star : Icons.star_border,
            color: Colors.amber,
          ),
          onPressed: () => onChanged(i + 1),
        );
      }),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: Colors.grey),
      ),
    );
  }
}
