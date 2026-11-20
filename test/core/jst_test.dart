import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/core/jst.dart';

void main() {
  group('toJst', () {
    test('UTC 15:00 はJSTの翌日 00:00 になる', () {
      expect(toJst(DateTime.utc(2026, 11, 12, 15)), DateTime(2026, 11, 13));
    });

    test('UTC 14:59:59 はJSTの同日 23:59:59 になる', () {
      expect(
        toJst(DateTime.utc(2026, 11, 12, 14, 59, 59)),
        DateTime(2026, 11, 12, 23, 59, 59),
      );
    });

    test('年をまたぐ', () {
      expect(toJst(DateTime.utc(2026, 12, 31, 15)), DateTime(2027, 1, 1));
    });
  });

  group('parseServerDate', () {
    test('旧形式（UTC 00:00）は同じ暦日として読める', () {
      expect(parseServerDate('2026-11-13T00:00:00+00:00'), DateTime(2026, 11, 13));
    });

    test('新形式（JST 00:00 = 前日 UTC 15:00）は同じ暦日として読める', () {
      expect(parseServerDate('2026-11-12T15:00:00+00:00'), DateTime(2026, 11, 13));
    });

    test('+09:00 のオフセット付きでも同じ暦日として読める', () {
      expect(parseServerDate('2026-11-13T00:00:00+09:00'), DateTime(2026, 11, 13));
    });

    test('Z 付きでも同じ暦日として読める', () {
      expect(parseServerDate('2026-11-13T00:00:00.000Z'), DateTime(2026, 11, 13));
    });

    test('時刻は 00:00 に正規化される', () {
      final d = parseServerDate('2026-11-13T05:30:00+00:00');
      expect(d, DateTime(2026, 11, 13));
    });

    test('不正な文字列は FormatException', () {
      expect(() => parseServerDate('invalid'), throwsFormatException);
    });
  });

  group('parseServerTimestamp', () {
    test('UTC をJSTの壁時計に変換する', () {
      expect(
        parseServerTimestamp('2026-11-13T06:00:00+00:00'),
        DateTime(2026, 11, 13, 15),
      );
    });
  });

  group('toServerDate', () {
    test('JST 00:00 のオフセット付き文字列になる（ゼロ埋め）', () {
      expect(toServerDate(DateTime(2026, 1, 5)), '2026-01-05T00:00:00+09:00');
    });

    test('時刻部分があっても暦日だけを使う', () {
      expect(
        toServerDate(DateTime(2026, 11, 13, 18, 30)),
        '2026-11-13T00:00:00+09:00',
      );
    });

    test('送信→読み取りで同じ暦日に戻る', () {
      for (final d in [
        DateTime(2026, 1, 1),
        DateTime(2026, 11, 13),
        DateTime(2026, 12, 31),
        DateTime(2028, 2, 29),
      ]) {
        expect(parseServerDate(toServerDate(d)), d);
      }
    });
  });

  group('serverTimestampNow', () {
    test('UTC（Z付き）の文字列を返す', () {
      final s = serverTimestampNow();
      expect(s.endsWith('Z'), isTrue);
      expect(DateTime.parse(s).isUtc, isTrue);
    });
  });

  group('todayJst', () {
    test('時刻が 00:00 である', () {
      final t = todayJst();
      expect(t, DateTime(t.year, t.month, t.day));
    });
  });
}
