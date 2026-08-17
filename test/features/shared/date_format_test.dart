import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/features/shared/date_format.dart';

void main() {
  group('formatSessionDate', () {
    test('xxxx/xx/xx (曜日) 形式で返す', () {
      expect(formatSessionDate(DateTime(2026, 7, 20)), '2026/07/20 (月)');
    });

    test('月日が1桁でも0埋めされる', () {
      expect(formatSessionDate(DateTime(2026, 1, 5)), '2026/01/05 (月)');
    });
  });
}
