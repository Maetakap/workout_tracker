import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/features/shared/workout_math.dart';

void main() {
  group('estimate1RM', () {
    test('reps=1 は重量そのまま', () {
      expect(estimate1RM(100, 1), 100);
    });

    test('reps=0 も重量そのまま', () {
      expect(estimate1RM(100, 0), 100);
    });

    test('Epley式：100kg×10rep = 133.33...', () {
      expect(estimate1RM(100, 10), closeTo(133.33, 0.01));
    });

    test('Epley式：60kg×5rep = 70', () {
      expect(estimate1RM(60, 5), closeTo(70.0, 0.01));
    });

    test('小数重量：62.5kg×8rep', () {
      expect(estimate1RM(62.5, 8), closeTo(79.17, 0.01));
    });
  });

  group('formatOneRm', () {
    test('null は記録なし表示', () {
      expect(formatOneRm(null), '1RM -- kg');
    });

    test('値ありは小数第1位まで', () {
      expect(formatOneRm(106.66), '1RM 106.7 kg');
    });

    test('整数値も小数第1位表示', () {
      expect(formatOneRm(100), '1RM 100.0 kg');
    });
  });
  group('formatOneRmValue', () {
    test('null は「--」', () {
      expect(formatOneRmValue(null), '--');
    });

    test('値ありは小数第1位まで（単位なし）', () {
      expect(formatOneRmValue(106.66), '106.7');
    });

    test('整数値も小数第1位表示', () {
      expect(formatOneRmValue(100), '100.0');
    });
  });
}
