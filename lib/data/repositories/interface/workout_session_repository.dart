import '../../database/app_database.dart';
import 'set_input.dart';

abstract interface class WorkoutSessionRepository {
  Future<List<WorkoutSession>> findAll();
  Future<List<WorkoutSession>> findByFilter({
    DateTime? monthStart,
    DateTime? monthEnd,
    int? exerciseId,
  });
  Future<WorkoutSession?> findById(int sessionId);

  Future<int> insert({
    required DateTime date,
    required int focusLevel,
    String? memo,
  });
  Future<void> update({
    required int sessionId,
    required DateTime date,
    required int focusLevel,
    String? memo,
  });
  Future<void> delete(int sessionId);

  // 複合操作（セッション＋セットを1トランザクションで保存）
  /// 新規セッションをセット群ごと保存し、採番されたsessionIdを返す
  Future<int> createSessionWithSets({
    required DateTime date,
    required int focusLevel,
    String? memo,
    required List<SetInput> sets,
  });

  /// 既存セッションをセット群ごと更新（全置換）
  Future<void> updateSessionWithSets({
    required int sessionId,
    required DateTime date,
    required int focusLevel,
    String? memo,
    required List<SetInput> sets,
  });
}
