import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/data/database/app_database.dart';
import 'package:workout_tracker/features/shared/workout_form_notifier.dart';
import 'package:workout_tracker/features/shared/workout_widgets.dart';
import 'package:workout_tracker/features/workout_input/workout_input_state.dart';

/// 呼び出しを記録するフェイクNotifier
class FakeFormNotifier implements WorkoutFormNotifier {
  final List<String> calls = [];
  int? addedSetCardIndex;
  int? removedCardIndex;

  @override
  void addExerciseCard() => calls.add('addExerciseCard');

  @override
  void removeExerciseCard(int cardIndex) {
    calls.add('removeExerciseCard');
    removedCardIndex = cardIndex;
  }

  @override
  void setExerciseId(int cardIndex, int exerciseId) =>
      calls.add('setExerciseId');

  @override
  void addSet(int cardIndex) {
    calls.add('addSet');
    addedSetCardIndex = cardIndex;
  }

  @override
  void removeSet(int cardIndex, int setIndex) => calls.add('removeSet');

  @override
  void updateWeight(int cardIndex, int setIndex, double? value) =>
      calls.add('updateWeight');

  @override
  void updateReps(int cardIndex, int setIndex, int? value) =>
      calls.add('updateReps');

  @override
  void updateRir(int cardIndex, int setIndex, int? value) =>
      calls.add('updateRir');
}

void main() {
  late FakeFormNotifier notifier;

  setUp(() {
    notifier = FakeFormNotifier();
  });

  ExerciseMaster makeExercise({required int id, required String name}) {
    return ExerciseMaster(
      exerciseId: id,
      name: name,
      sortOrder: 0,
      createdAt: DateTime(2026, 1, 1),
    );
  }

  /// ExerciseCardをpumpするヘルパー
  Future<void> pumpExerciseCard(
    WidgetTester tester, {
    required ExerciseCardState card,
    required List<ExerciseMaster> exercises,
    bool canRemove = true,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ExerciseCard(
              cardIndex: 0,
              card: card,
              exercises: exercises,
              canRemove: canRemove,
              notifier: notifier,
            ),
          ),
        ),
      ),
    );
  }

  group('ExerciseCard', () {
    testWidgets('1. 種目未選択：プレースホルダーが表示される', (tester) async {
      await pumpExerciseCard(
        tester,
        card: ExerciseCardState(),
        exercises: [makeExercise(id: 1, name: 'ベンチプレス')],
      );

      expect(find.text('種目を選択'), findsOneWidget);
    });

    testWidgets('2. 種目選択済み：種目名が表示される', (tester) async {
      await pumpExerciseCard(
        tester,
        card: ExerciseCardState(exerciseId: 1),
        exercises: [makeExercise(id: 1, name: 'ベンチプレス')],
      );

      expect(find.text('ベンチプレス'), findsOneWidget);
    });

    testWidgets('3. セット行が件数分表示される', (tester) async {
      await pumpExerciseCard(
        tester,
        card: ExerciseCardState(
          exerciseId: 1,
          sets: [SetRowState(), SetRowState(), SetRowState()],
        ),
        exercises: [makeExercise(id: 1, name: 'ベンチプレス')],
      );

      // SetRowが3行表示される（S1・S2・S3）
      expect(find.text('S1'), findsOneWidget);
      expect(find.text('S2'), findsOneWidget);
      expect(find.text('S3'), findsOneWidget);
    });

    testWidgets('4. 「セット追加」をタップするとaddSetが呼ばれる', (tester) async {
      await pumpExerciseCard(
        tester,
        card: ExerciseCardState(exerciseId: 1),
        exercises: [makeExercise(id: 1, name: 'ベンチプレス')],
      );

      await tester.tap(find.text('セット追加'));
      await tester.pump();

      expect(notifier.calls, contains('addSet'));
      expect(notifier.addedSetCardIndex, 0);
    });

    testWidgets('5. カード削除ボタンをタップするとremoveExerciseCardが呼ばれる', (tester) async {
      await pumpExerciseCard(
        tester,
        card: ExerciseCardState(exerciseId: 1),
        exercises: [makeExercise(id: 1, name: 'ベンチプレス')],
        canRemove: true,
      );

      // カード右上の削除ボタン（最初のclose）をタップ
      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pump();

      expect(notifier.calls, contains('removeExerciseCard'));
      expect(notifier.removedCardIndex, 0);
    });

    testWidgets('6. canRemove=falseのときカード削除ボタンが表示されない', (tester) async {
      await pumpExerciseCard(
        tester,
        card: ExerciseCardState(
          exerciseId: 1,
          sets: [SetRowState()], // セット1件なのでセット削除ボタンも非表示
        ),
        exercises: [makeExercise(id: 1, name: 'ベンチプレス')],
        canRemove: false,
      );

      // カード削除・セット削除ともになし → closeアイコンは0個
      expect(find.byIcon(Icons.close), findsNothing);
    });
  });
}
