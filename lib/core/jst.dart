/// 日本標準時（JST・UTC+9）の扱いをまとめたユーティリティ。
///
/// 日本は夏時間がないため固定オフセットで表現でき、端末やブラウザの
/// タイムゾーン設定に依存せず、常にJSTの日付・時刻として扱える。
library;

const Duration jstOffset = Duration(hours: 9);

/// 任意の時刻（瞬間）を、JSTの壁時計の値を持つ [DateTime] に変換する。
///
/// 戻り値の year / month / day / hour などがJSTの日時を表す。
/// タイムゾーン情報は持たない（ローカル扱い）ため、表示と暦日の比較にだけ使う。
DateTime toJst(DateTime instant) {
  final j = instant.toUtc().add(jstOffset);
  return DateTime(
    j.year,
    j.month,
    j.day,
    j.hour,
    j.minute,
    j.second,
    j.millisecond,
    j.microsecond,
  );
}

/// 現在時刻（JSTの壁時計）。
DateTime nowJst() => toJst(DateTime.now());

/// JSTの今日の日付（時刻 00:00）。
DateTime todayJst() {
  final now = nowJst();
  return DateTime(now.year, now.month, now.day);
}

/// サーバーのタイムスタンプ文字列を、JSTの暦日（時刻 00:00）に変換する。
///
/// 旧形式（暦日を UTC 00:00 として保存）と新形式（JST 00:00 として保存）の
/// どちらも、同じ暦日として読める。
/// 形式が不正な場合は [FormatException] を投げる。
DateTime parseServerDate(String iso) {
  final jst = toJst(DateTime.parse(iso));
  return DateTime(jst.year, jst.month, jst.day);
}

/// サーバーのタイムスタンプ文字列を、JSTの壁時計の [DateTime] に変換する。
///
/// 形式が不正な場合は [FormatException] を投げる。
DateTime parseServerTimestamp(String iso) => toJst(DateTime.parse(iso));

/// JSTの暦日を、サーバーへ送る文字列（JST 00:00・オフセット付き）に変換する。
///
/// [date] は year / month / day がJSTの暦日を表す値であること。
String toServerDate(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-${d}T00:00:00+09:00';
}

/// 現在時刻を、サーバーへ送る文字列（UTC・Z付き）で返す。
String serverTimestampNow() => DateTime.now().toUtc().toIso8601String();
