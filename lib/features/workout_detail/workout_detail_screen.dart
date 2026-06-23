import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/database/app_database.dart';
import '../../data/providers.dart';
import '../shared/confirm_dialog.dart';
import '../workout_list/workout_list_notifier.dart';
import 'workout_detail_provider.dart';

// 💡 レイアウト共通の定数
const double _setNumberWidth = 32.0; // セット番号の幅
const double _badgeSpacing = 6.0; // バッジ間の隙間

class WorkoutDetailScreen extends ConsumerWidget {
  const WorkoutDetailScreen({super.key, required this.sessionId});

  final int sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(workoutDetailProvider(sessionId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('詳細'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/list/detail/$sessionId/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('エラー: $e')),
        data: (data) {
          if (data == null) {
            return const Center(child: Text('データが見つかりません'));
          }
          return _DetailBody(data: data);
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'セッションを削除',
      content: 'このセッションを削除しますか？\nセット記録もすべて削除されます。',
    );
    if (confirmed && context.mounted) {
      await ref.read(workoutSetRepositoryProvider).deleteBySessionId(sessionId);
      await ref.read(workoutSessionRepositoryProvider).delete(sessionId);
      ref.invalidate(workoutListProvider);
      if (context.mounted) context.go('/list');
    }
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.data});

  final WorkoutDetailData data;

  @override
  Widget build(BuildContext context) {
    final session = data.session;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ヘッダー：日付・没頭度
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDate(session.date),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '没頭度',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
                const SizedBox(width: 4),
                _StarDisplay(focusLevel: session.focusLevel),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 種目ごとのセクション
        ...data.groups.map((group) => _ExerciseSection(group: group)),

        // メモ
        if (session.memo != null && session.memo!.isNotEmpty) ...[
          const Divider(),
          const SizedBox(height: 8),
          Text(
            'メモ',
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(session.memo!, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ],
    );
  }

  String _formatDate(DateTime date) {
    const weekdays = ['月', '火', '水', '木', '金', '土', '日'];
    final weekday = weekdays[date.weekday - 1];
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')} ($weekday)';
  }
}

class _ExerciseSection extends StatelessWidget {
  const _ExerciseSection({required this.group});

  final ExerciseSetGroup group;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            group.exerciseName,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(width: _setNumberWidth),
              Expanded(
                child: Center(
                  child: Text(
                    'kg',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ),
              SizedBox(width: _badgeSpacing),
              Expanded(
                child: Center(
                  child: Text(
                    'REP',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ),
              SizedBox(width: _badgeSpacing),
              Expanded(
                child: Center(
                  child: Text(
                    'RIR',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
        ),
        ...group.sets.asMap().entries.map((entry) {
          final i = entry.key;
          final set = entry.value;
          return _SetRow(index: i, set: set);
        }),
      ],
    );
  }
}

class _SetRow extends StatelessWidget {
  const _SetRow({required this.index, required this.set});

  final int index;
  final WorkoutSet set;

  @override
  Widget build(BuildContext context) {
    final weight = set.weightKg % 1 == 0
        ? set.weightKg.toInt().toString()
        : set.weightKg.toString();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: _setNumberWidth,
            child: Text(
              'S${index + 1}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ),
          Expanded(child: _Badge(weight)),
          const SizedBox(width: _badgeSpacing),
          Expanded(child: _Badge(set.reps.toString())),
          const SizedBox(width: _badgeSpacing),
          Expanded(child: _Badge(set.rir.toString())),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _StarDisplay extends StatelessWidget {
  const _StarDisplay({required this.focusLevel});

  final int focusLevel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < focusLevel ? Icons.star : Icons.star_border,
          size: 18,
          color: Colors.amber,
        );
      }),
    );
  }
}
