import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/data/database/app_database.dart';
import 'package:workout_tracker/features/exercise_master/exercise_master_notifier.dart';
import 'package:workout_tracker/features/exercise_master/exercise_master_screen.dart';
import 'package:workout_tracker/features/exercise_master/exercise_master_state.dart';

void main() {
  /// テスト用ExerciseMasterを生成
  ExerciseMaster makeExercise({required int id, required String name}) {
    return ExerciseMaster(
      exerciseId: id,
      name: name,
      sortOrder: 0,
      createdAt: DateTime(2026, 1, 1),
    );
  }

  /// 指定した状態でExerciseMasterScreenをpumpする
  Future<void> pumpScreen(
    WidgetTester tester, {
    required ExerciseMasterState state,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          exerciseMasterProvider.overrideWith(
            () => _FakeExerciseMasterNotifier(state),
          ),
        ],
        child: const MaterialApp(home: ExerciseMasterScreen()),
      ),
    );
    await tester.pump();
  }

  group('ExerciseMasterScreen', () {
    testWidgets('1. 種目一覧が表示される', (tester) async {
      await pumpScreen(
        tester,
        state: ExerciseMasterState(
          exercises: [
            makeExercise(id: 1, name: 'ベンチプレス'),
            makeExercise(id: 2, name: 'スクワット'),
          ],
        ),
      );

      expect(find.text('ベンチプレス'), findsOneWidget);
      expect(find.text('スクワット'), findsOneWidget);
    });

    testWidgets('2. 0件時に空状態UIが表示される', (tester) async {
      await pumpScreen(tester, state: const ExerciseMasterState(exercises: []));

      expect(find.text('種目がありません'), findsOneWidget);
    });

    testWidgets('3. ＋ボタンで追加ダイアログが開く', (tester) async {
      await pumpScreen(tester, state: const ExerciseMasterState(exercises: []));

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.text('種目を追加'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('4. ローディング中はインジケーターが表示される', (tester) async {
      await pumpScreen(
        tester,
        state: const ExerciseMasterState(isLoading: true),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}

/// 指定した状態を返すExerciseMasterNotifier（テスト用）
class _FakeExerciseMasterNotifier extends ExerciseMasterNotifier {
  _FakeExerciseMasterNotifier(this._initialState);

  final ExerciseMasterState _initialState;

  @override
  ExerciseMasterState build() => _initialState;
}
