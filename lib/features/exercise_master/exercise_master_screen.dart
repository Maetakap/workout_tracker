import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../shared/confirm_dialog.dart';
import '../shared/swipeable_list_item.dart';
import '../shared/workout_math.dart';
import '../shared/one_rm_provider.dart';
import 'exercise_master_notifier.dart';

// 💡 レイアウト共通の定数
const double _weightKgWidth = 80.0; // 1RMバッジの幅

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
          : Column(
              children: [
                // リスト上部の「1RM」見出し
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: _weightKgWidth,
                        child: Text(
                          '1RM',
                          textAlign: TextAlign.center,
                          style: Theme.of(
                            context,
                          ).textTheme.labelMedium?.copyWith(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ReorderableListView.builder(
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
                        child: Padding(
                          key: ValueKey(exercise.exerciseId),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              // ドラッグハンドル
                              ReorderableDragStartListener(
                                index: index,
                                child: const Icon(
                                  Icons.drag_handle,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // 種目名
                              Expanded(
                                child: Text(
                                  exercise.name,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // 1RMバッジ
                              _OneRmBadge(value: oneRmMap[exercise.exerciseId]),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
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
        // ① 画面端からの余白を確保（上に張り付きすぎるのを防ぐ）
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        title: Text(title),
        // ② 中身をスクロール可能にする（縦が詰まっても救える）
        content: SingleChildScrollView(
          child: TextField(
            controller: controller,
            maxLength: 30,
            decoration: const InputDecoration(hintText: '種目名'),
          ),
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

/// 1RM表示バッジ（xx kg を角丸の箱で表示・固定幅・中央寄せ）
/// 1RM表示バッジ（詳細画面の_Badgeを踏襲・固定幅80）
class _OneRmBadge extends StatelessWidget {
  const _OneRmBadge({required this.value});

  final double? value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _weightKgWidth,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${formatOneRmValue(value)} kg',
        style: Theme.of(context).textTheme.bodyMedium,
        textAlign: TextAlign.center,
      ),
    );
  }
}
