import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/features/shared/workout_form_notifier.dart';
import 'package:workout_tracker/features/shared/workout_widgets.dart';
import 'package:workout_tracker/features/workout_input/workout_input_state.dart';

/// 呼び出しを記録するフェイクNotifier
class FakeFormNotifier implements WorkoutFormNotifier {
  final List<String> calls = [];
  double? lastWeight;
  int? lastReps;
  int? lastRir;
  int? removedCardIndex;
  int? removedSetCardIndex;
  int? removedSetIndex;

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
  void addSet(int cardIndex) => calls.add('addSet');

  @override
  void removeSet(int cardIndex, int setIndex) {
    calls.add('removeSet');
    removedSetCardIndex = cardIndex;
    removedSetIndex = setIndex;
  }

  @override
  void updateWeight(int cardIndex, int setIndex, double? value) {
    calls.add('updateWeight');
    lastWeight = value;
  }

  @override
  void updateReps(int cardIndex, int setIndex, int? value) {
    calls.add('updateReps');
    lastReps = value;
  }

  @override
  void updateRir(int cardIndex, int setIndex, int? value) {
    calls.add('updateRir');
    lastRir = value;
  }
}

void main() {
  late FakeFormNotifier notifier;

  setUp(() {
    notifier = FakeFormNotifier();
  });

  /// SetRowをpumpするヘルパー
  Future<void> pumpSetRow(
    WidgetTester tester, {
    required SetRowState set,
    bool canRemove = true,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SetRow(
            cardIndex: 0,
            setIndex: 0,
            set: set,
            canRemove: canRemove,
            notifier: notifier,
          ),
        ),
      ),
    );
  }

  group('SetRow', () {
    testWidgets('1. 初期値なし：kg・REPが空欄', (tester) async {
      await pumpSetRow(tester, set: SetRowState());

      // TextFieldが2つ（kg・REP）
      expect(find.byType(TextField), findsNWidgets(2));
    });

    testWidgets('2. 初期値あり：各値が表示される', (tester) async {
      await pumpSetRow(
        tester,
        set: SetRowState(weightKg: 60.0, reps: 10, rir: 2),
      );

      expect(find.text('60'), findsOneWidget); // 整数表示
      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('3. 重量を入力するとupdateWeightが呼ばれる', (tester) async {
      await pumpSetRow(tester, set: SetRowState());

      // 1つ目のTextField（kg）に入力
      await tester.enterText(find.byType(TextField).at(0), '80');
      await tester.pump();

      expect(notifier.calls, contains('updateWeight'));
      expect(notifier.lastWeight, 80.0);
    });

    testWidgets('4. 回数を入力するとupdateRepsが呼ばれる', (tester) async {
      await pumpSetRow(tester, set: SetRowState());

      // 2つ目のTextField（REP）に入力
      await tester.enterText(find.byType(TextField).at(1), '12');
      await tester.pump();

      expect(notifier.calls, contains('updateReps'));
      expect(notifier.lastReps, 12);
    });

    testWidgets('5. RIRを変更するとupdateRirが呼ばれる', (tester) async {
      await pumpSetRow(tester, set: SetRowState());

      // RIRドロップダウンを開く
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();

      // 値「3」を選択（ドロップダウンメニュー内）
      await tester.tap(find.text('3').last);
      await tester.pumpAndSettle();

      expect(notifier.calls, contains('updateRir'));
      expect(notifier.lastRir, 3);
    });

    testWidgets('6. 削除ボタンをタップするとremoveSetが呼ばれる', (tester) async {
      await pumpSetRow(tester, set: SetRowState(), canRemove: true);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(notifier.calls, contains('removeSet'));
      expect(notifier.removedSetCardIndex, 0);
      expect(notifier.removedSetIndex, 0);
    });

    testWidgets('7. canRemove=falseのとき削除ボタンが表示されない', (tester) async {
      await pumpSetRow(tester, set: SetRowState(), canRemove: false);

      expect(find.byIcon(Icons.close), findsNothing);
    });
  });
}
