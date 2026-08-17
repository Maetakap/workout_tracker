const _weekdays = ['月', '火', '水', '木', '金', '土', '日'];

/// セッション日付の表示用フォーマット（例：2026/07/20 (月)）
String formatSessionDate(DateTime date) {
  final weekday = _weekdays[date.weekday - 1];
  return '${date.year}/${date.month.toString().padLeft(2, '0')}/'
      '${date.day.toString().padLeft(2, '0')} ($weekday)';
}
