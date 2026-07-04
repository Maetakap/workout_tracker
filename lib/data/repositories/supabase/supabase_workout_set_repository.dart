import 'package:supabase_flutter/supabase_flutter.dart';
import '../../database/app_database.dart';
import '../interface/workout_set_repository.dart';

class SupabaseWorkoutSetRepository implements WorkoutSetRepository {
  final SupabaseClient _client;

  SupabaseWorkoutSetRepository(this._client);

  WorkoutSet _fromMap(Map<String, dynamic> m) {
    return WorkoutSet(
      setId: m['setId'] as int,
      sessionId: m['sessionId'] as int,
      exerciseId: m['exerciseId'] as int,
      setOrder: m['setOrder'] as int,
      weightKg: (m['weightKg'] as num).toDouble(),
      reps: m['reps'] as int,
      rir: m['rir'] as int,
      createdAt: DateTime.parse(m['createdAt'] as String),
    );
  }

  // Companion → RPCに渡すJSON要素（setId・user_id・createdAtは含めない）
  Map<String, dynamic> _toJson(WorkoutSetsCompanion c) {
    return {
      'sessionId': c.sessionId.value,
      'exerciseId': c.exerciseId.value,
      'setOrder': c.setOrder.value,
      'weightKg': c.weightKg.value,
      'reps': c.reps.value,
      'rir': c.rir.value,
    };
  }

  @override
  Future<List<WorkoutSet>> findBySessionId(int sessionId) async {
    final rows = await _client
        .from('workout_sets')
        .select()
        .eq('sessionId', sessionId)
        .order('setOrder', ascending: true);
    return rows.map(_fromMap).toList();
  }

  @override
  Future<void> insertAll(List<WorkoutSetsCompanion> sets) async {
    // 新規保存もRPCで処理（該当sessionに既存セットが無ければ削除は空振り）
    if (sets.isEmpty) return;
    final sessionId = sets.first.sessionId.value;
    await _replace(sessionId, sets);
  }

  @override
  Future<void> replaceAll(
    int sessionId,
    List<WorkoutSetsCompanion> sets,
  ) async {
    await _replace(sessionId, sets);
  }

  // RPC呼び出し（トランザクションで削除→一括insert）
  Future<void> _replace(int sessionId, List<WorkoutSetsCompanion> sets) async {
    await _client.rpc(
      'replace_workout_sets',
      params: {'p_session_id': sessionId, 'p_sets': sets.map(_toJson).toList()},
    );
  }

  @override
  Future<void> deleteBySessionId(int sessionId) async {
    await _client.from('workout_sets').delete().eq('sessionId', sessionId);
  }

  @override
  Future<List<WorkoutSet>> findAll() async {
    final rows = await _client.from('workout_sets').select();
    return rows.map(_fromMap).toList();
  }
}
