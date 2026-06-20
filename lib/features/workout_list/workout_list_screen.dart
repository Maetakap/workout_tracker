import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/providers.dart';
import '../shared/confirm_dialog.dart';
import '../shared/swipeable_list_item.dart';
import 'workout_list_notifier.dart';

class WorkoutListScreen extends ConsumerWidget {
  const WorkoutListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workoutListProvider);
    final notifier = ref.read(workoutListProvider.notifier);
    final sessions = state.filteredSessions;

    return Scaffold(
      appBar: AppBar(title: const Text('記録一覧')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                // 月フィルター
                Expanded(
                  child: _MonthFilterDropdown(
                    availableMonths: state.availableMonths,
                    selectedMonth: state.selectedMonth,
                    onChanged: notifier.setMonthFilter,
                  ),
                ),
                const SizedBox(width: 8),
                // 種目フィルター
                Expanded(
                  child: _ExerciseFilterDropdown(
                    exercises: state.exercises,
                    selectedExerciseId: state.selectedExerciseId,
                    onChanged: notifier.setExerciseFilter,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : sessions.isEmpty
                ? const Center(child: Text('記録がありません'))
                : ListView.separated(
                    itemCount: sessions.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final session = sessions[index];
                      final exerciseNames = state.exerciseNamesForSession(
                        session.sessionId,
                      );
                      final setCount = state.setCountForSession(
                        session.sessionId,
                      );
                      return SwipeableListItem(
                        key: ValueKey(session.sessionId),
                        onDeleteConfirm: () => showConfirmDialog(
                          context,
                          title: 'セッションを削除',
                          content: 'このセッションを削除しますか？',
                        ),
                        onEdit: () => context.push(
                          '/list/detail/${session.sessionId}/edit',
                        ),
                        onDeleted: () async {
                          await ref
                              .read(workoutSessionRepositoryProvider)
                              .delete(session.sessionId);
                          await ref
                              .read(workoutSetRepositoryProvider)
                              .deleteBySessionId(session.sessionId);
                          ref.invalidate(workoutListProvider);
                        },
                        child: ListTile(
                          title: Text(_formatDate(session.date)),
                          subtitle: Text(
                            '${exerciseNames.join('・')} · $setCount セット',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: _StarDisplay(
                            focusLevel: session.focusLevel,
                          ),
                          onTap: () =>
                              context.push('/list/detail/${session.sessionId}'),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}

class _MonthFilterDropdown extends StatelessWidget {
  final List<int> availableMonths;
  final int? selectedMonth;
  final ValueChanged<int?> onChanged;

  const _MonthFilterDropdown({
    required this.availableMonths,
    required this.selectedMonth,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int?>(
      initialValue: selectedMonth,
      isExpanded: true,
      isDense: true,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('全期間')),
        ...availableMonths.map(
          (m) => DropdownMenuItem(
            value: m,
            child: Text('${m ~/ 100}年${(m % 100).toString().padLeft(2, '0')}月'),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}

class _ExerciseFilterDropdown extends StatelessWidget {
  final List exercises;
  final int? selectedExerciseId;
  final ValueChanged<int?> onChanged;

  const _ExerciseFilterDropdown({
    required this.exercises,
    required this.selectedExerciseId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int?>(
      initialValue: selectedExerciseId,
      isExpanded: true,
      isDense: true,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('すべての種目')),
        ...exercises.map(
          (e) => DropdownMenuItem(
            value: e.exerciseId,
            child: Text(e.name, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}

class _StarDisplay extends StatelessWidget {
  final int focusLevel;

  const _StarDisplay({required this.focusLevel});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < focusLevel ? Icons.star : Icons.star_border,
          size: 14,
          color: Colors.amber,
        );
      }),
    );
  }
}
