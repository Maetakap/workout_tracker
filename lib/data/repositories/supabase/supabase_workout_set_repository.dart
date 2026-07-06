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
  Future<void> deleteBySessionId(int sessionId) async {
    await _client.from('workout_sets').delete().eq('sessionId', sessionId);
  }

  @override
  Future<List<WorkoutSet>> findAll() async {
    final rows = await _client.from('workout_sets').select();
    return rows.map(_fromMap).toList();
  }
}
