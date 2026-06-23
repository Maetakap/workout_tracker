import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:workout_tracker/data/database/app_database.dart';
import 'package:workout_tracker/features/workout_detail/workout_detail_provider.dart';
import 'package:workout_tracker/features/workout_detail/workout_detail_screen.dart';

void main() {
  WorkoutSession makeSession({String? memo}) {
    return WorkoutSession(
      sessionId: 1,
      date: DateTime(2026, 6, 1),
      focusLevel: 4,
      memo: memo,
      createdAt: DateTime(2026, 6, 1),
    );
  }

  WorkoutSet makeSet({required int setOrder}) {
    return WorkoutSet(
      setId: setOrder + 1,
      sessionId: 1,
      exerciseId: 10,
      setOrder: setOrder,
      weightKg: 60.0,
      reps: 10,
      rir: 2,
      createdAt: DateTime(2026, 6, 1),
    );
  }

  /// 指定データでDetailScreenをpumpする
  Future<void> pumpDetail(
    WidgetTester tester, {
    required AsyncValue<WorkoutDetailData?> detailValue,
  }) async {
    // go_routerのcontext.push/goが動くよう最低限のrouterを用意
    final router = GoRouter(
      initialLocation: '/list/detail/1',
      routes: [
        GoRoute(
          path: '/list/detail/1',
          builder: (_, _) => const WorkoutDetailScreen(sessionId: 1),
        ),
        GoRoute(path: '/list', builder: (_, _) => const Scaffold()),
        GoRoute(
          path: '/list/detail/1/edit',
          builder: (_, _) => const Scaffold(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          workoutDetailProvider(1).overrideWith((ref) {
            // AsyncValueの内容に応じて返す
            return detailValue.when(
              data: (d) => d,
              loading: () =>
                  Future.delayed(const Duration(seconds: 10), () => null),
              error: (e, _) => Future.error(e),
            );
          }),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
  }

  group('WorkoutDetailScreen', () {
    testWidgets('1. セッション情報が表示される', (tester) async {
      final data = WorkoutDetailData(
        session: makeSession(),
        groups: [
          ExerciseSetGroup(
            exerciseName: 'ベンチプレス',
            sets: [makeSet(setOrder: 0)],
          ),
        ],
      );

      await pumpDetail(tester, detailValue: AsyncData(data));
      await tester.pumpAndSettle();

      // 日付（曜日付き）
      expect(find.textContaining('2026/06/01'), findsOneWidget);
      // 没頭度ラベル
      expect(find.text('没頭度'), findsOneWidget);
    });

    testWidgets('2. 種目ごとのセクション・セット行が表示される', (tester) async {
      final data = WorkoutDetailData(
        session: makeSession(),
        groups: [
          ExerciseSetGroup(
            exerciseName: 'ベンチプレス',
            sets: [makeSet(setOrder: 0), makeSet(setOrder: 1)],
          ),
        ],
      );

      await pumpDetail(tester, detailValue: AsyncData(data));
      await tester.pumpAndSettle();

      expect(find.text('ベンチプレス'), findsOneWidget);
      expect(find.text('S1'), findsOneWidget);
      expect(find.text('S2'), findsOneWidget);
      expect(find.text('60'), findsNWidgets(2)); // kg値
    });

    testWidgets('3. メモがある場合に表示される', (tester) async {
      final data = WorkoutDetailData(
        session: makeSession(memo: '今日は調子が良かった'),
        groups: [
          ExerciseSetGroup(
            exerciseName: 'ベンチプレス',
            sets: [makeSet(setOrder: 0)],
          ),
        ],
      );

      await pumpDetail(tester, detailValue: AsyncData(data));
      await tester.pumpAndSettle();

      expect(find.text('メモ'), findsOneWidget);
      expect(find.text('今日は調子が良かった'), findsOneWidget);
    });

    testWidgets('4. メモがない場合は表示されない', (tester) async {
      final data = WorkoutDetailData(
        session: makeSession(memo: null),
        groups: [
          ExerciseSetGroup(
            exerciseName: 'ベンチプレス',
            sets: [makeSet(setOrder: 0)],
          ),
        ],
      );

      await pumpDetail(tester, detailValue: AsyncData(data));
      await tester.pumpAndSettle();

      expect(find.text('メモ'), findsNothing);
    });

    testWidgets('5. データが見つからない場合のメッセージ', (tester) async {
      await pumpDetail(tester, detailValue: const AsyncData(null));
      await tester.pumpAndSettle();

      expect(find.text('データが見つかりません'), findsOneWidget);
    });

    testWidgets('6. 編集・削除ボタンが表示される', (tester) async {
      final data = WorkoutDetailData(
        session: makeSession(),
        groups: [
          ExerciseSetGroup(
            exerciseName: 'ベンチプレス',
            sets: [makeSet(setOrder: 0)],
          ),
        ],
      );

      await pumpDetail(tester, detailValue: AsyncData(data));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.edit), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsOneWidget);
    });
  });
}
