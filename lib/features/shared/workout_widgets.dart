import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/app_database.dart';
import '../workout_input/workout_input_state.dart';
import 'workout_form_notifier.dart';

/// 保存ボタン固定バー（入力・編集画面で共通利用）
class SaveBar extends StatelessWidget {
  const SaveBar({
    super.key,
    required this.canSave,
    required this.isSaving,
    required this.onSave,
  });

  final bool canSave;
  final bool isSaving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: FilledButton(
        onPressed: canSave ? onSave : null,
        child: isSaving
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
    );
  }
}

/// スター入力（セッション単位の没頭度）
class StarInput extends StatelessWidget {
  const StarInput({super.key, required this.value, required this.onChanged});

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

/// セクションラベル
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.label, {super.key});

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

/// セット行（入力・編集画面で共通利用）
class SetRow extends StatefulWidget {
  const SetRow({
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
  final WorkoutFormNotifier notifier;

  @override
  State<SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<SetRow> {
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
                isDense: true,
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

/// 種目カード（入力・編集画面で共通利用）
class ExerciseCard extends ConsumerWidget {
  const ExerciseCard({
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
  final WorkoutFormNotifier notifier;

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
              return SetRow(
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
