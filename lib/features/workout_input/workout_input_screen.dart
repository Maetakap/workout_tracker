import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/database/app_database.dart';
import '../exercise_master/exercise_master_notifier.dart';
import '../shared/workout_widgets.dart';
import 'workout_input_notifier.dart';
import 'workout_input_state.dart';

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
                  return _ExerciseCard(
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

class _ExerciseCard extends ConsumerWidget {
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
  final WorkoutInputNotifier notifier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
  final WorkoutInputNotifier notifier;

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

  /// 小数が不要な場合は整数表示（65.0 → 65）
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
          // kg
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
          // REP
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
          // RIR
          Expanded(
            child: DropdownButtonFormField<int>(
              // ignore: deprecated_member_use
              value: widget.set.rir,
              isDense: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
              ),
              items: List.generate(
                6,
                (i) => DropdownMenuItem(value: i, child: Text('$i')),
              ),
              onChanged: (v) => widget.notifier.updateRir(
                widget.cardIndex,
                widget.setIndex,
                v,
              ),
            ),
          ),
          // 削除
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
