import 'package:supabase_flutter/supabase_flutter.dart';
import '../../database/app_database.dart';
import '../interface/workout_session_repository.dart';

class SupabaseWorkoutSessionRepository implements WorkoutSessionRepository {
  final SupabaseClient _client;

  SupabaseWorkoutSessionRepository(this._client);

  WorkoutSession _fromMap(Map<String, dynamic> m) {
    return WorkoutSession(
      sessionId: m['sessionId'] as int,
      date: DateTime.parse(m['date'] as String),
      focusLevel: m['focusLevel'] as int,
      memo: m['memo'] as String?,
      createdAt: DateTime.parse(m['createdAt'] as String),
    );
  }

  @override
  Future<List<WorkoutSession>> findAll() async {
    final rows = await _client
        .from('workout_sessions')
        .select()
        .order('date', ascending: false);
    return rows.map(_fromMap).toList();
  }

  @override
  Future<List<WorkoutSession>> findByFilter({
    DateTime? monthStart,
    DateTime? monthEnd,
    int? exerciseId,
  }) async {
    Set<int>? filteredSessionIds;
    if (exerciseId != null) {
      final sets = await _client
          .from('workout_sets')
          .select('sessionId')
          .eq('exerciseId', exerciseId);
      filteredSessionIds = sets.map((s) => s['sessionId'] as int).toSet();
      if (filteredSessionIds.isEmpty) return [];
    }

    var query = _client.from('workout_sessions').select();
    if (monthStart != null) {
      query = query.gte('date', monthStart.toIso8601String());
    }
    if (monthEnd != null) {
      query = query.lt('date', monthEnd.toIso8601String());
    }
    if (filteredSessionIds != null) {
      query = query.inFilter('sessionId', filteredSessionIds.toList());
    }
    final rows = await query.order('date', ascending: false);
    return rows.map(_fromMap).toList();
  }

  @override
  Future<WorkoutSession?> findById(int sessionId) async {
    final row = await _client
        .from('workout_sessions')
        .select()
        .eq('sessionId', sessionId)
        .maybeSingle();
    return row == null ? null : _fromMap(row);
  }

  @override
  Future<int> insert({
    required DateTime date,
    required int focusLevel,
    String? memo,
  }) async {
    final row = await _client
        .from('workout_sessions')
        .insert({
          'date': date.toIso8601String(),
          'focusLevel': focusLevel,
          'memo': memo,
          'createdAt': DateTime.now().toIso8601String(),
        })
        .select('sessionId')
        .single();
    return row['sessionId'] as int;
  }

  @override
  Future<void> update({
    required int sessionId,
    required DateTime date,
    required int focusLevel,
    String? memo,
  }) async {
    await _client
        .from('workout_sessions')
        .update({
          'date': date.toIso8601String(),
          'focusLevel': focusLevel,
          'memo': memo,
        })
        .eq('sessionId', sessionId);
  }

  @override
  Future<void> delete(int sessionId) async {
    await _client.from('workout_sessions').delete().eq('sessionId', sessionId);
  }
}
