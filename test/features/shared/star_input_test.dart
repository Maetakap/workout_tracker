import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/features/shared/workout_widgets.dart';

void main() {
  /// StarInputをpumpするヘルパー
  Future<void> pumpStarInput(
    WidgetTester tester, {
    required int? value,
    required ValueChanged<int> onChanged,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StarInput(value: value, onChanged: onChanged),
        ),
      ),
    );
  }

  group('StarInput', () {
    testWidgets('1. 初期値なし：全スターが未選択（star_border）', (tester) async {
      await pumpStarInput(tester, value: null, onChanged: (_) {});

      expect(find.byIcon(Icons.star_border), findsNWidgets(5));
      expect(find.byIcon(Icons.star), findsNothing);
    });

    testWidgets('2. value=3：スター3つが選択状態', (tester) async {
      await pumpStarInput(tester, value: 3, onChanged: (_) {});

      expect(find.byIcon(Icons.star), findsNWidgets(3));
      expect(find.byIcon(Icons.star_border), findsNWidgets(2));
    });

    testWidgets('3. value=5：全スターが選択状態', (tester) async {
      await pumpStarInput(tester, value: 5, onChanged: (_) {});

      expect(find.byIcon(Icons.star), findsNWidgets(5));
      expect(find.byIcon(Icons.star_border), findsNothing);
    });

    testWidgets('4. スターをタップするとonChangedが呼ばれる', (tester) async {
      int? tappedValue;
      await pumpStarInput(
        tester,
        value: null,
        onChanged: (v) => tappedValue = v,
      );

      // 4番目のスターをタップ（0-indexなので index=3）
      await tester.tap(find.byIcon(Icons.star_border).at(3));
      await tester.pump();

      expect(tappedValue, 4);
    });

    testWidgets('5. 1番目のスターをタップすると1が返る', (tester) async {
      int? tappedValue;
      await pumpStarInput(
        tester,
        value: null,
        onChanged: (v) => tappedValue = v,
      );

      await tester.tap(find.byIcon(Icons.star_border).first);
      await tester.pump();

      expect(tappedValue, 1);
    });
  });
}
