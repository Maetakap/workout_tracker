import 'package:supabase_flutter/supabase_flutter.dart';
import '../../database/app_database.dart';
import '../interface/exercise_master_repository.dart';

class SupabaseExerciseMasterRepository implements ExerciseMasterRepository {
  final SupabaseClient _client;

  SupabaseExerciseMasterRepository(this._client);

  // SupabaseのMap → Drift型(ExerciseMaster)へ詰め替え
  ExerciseMaster _fromMap(Map<String, dynamic> map) {
    return ExerciseMaster(
      exerciseId: map['exerciseId'] as int,
      name: map['name'] as String,
      sortOrder: map['sortOrder'] as int,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  @override
  Future<List<ExerciseMaster>> findAll() async {
    final rows = await _client
        .from('exercise_masters')
        .select()
        .order('sortOrder', ascending: true);
    return rows.map((r) => _fromMap(r)).toList();
  }

  @override
  Future<int> insert(String name, int sortOrder) async {
    // user_idはトリガーで自動セットされるので送らない
    final row = await _client
        .from('exercise_masters')
        .insert({
          'name': name,
          'sortOrder': sortOrder,
          'createdAt': DateTime.now().toIso8601String(),
        })
        .select('exerciseId')
        .single();
    return row['exerciseId'] as int;
  }

  @override
  Future<void> updateName(int exerciseId, String name) async {
    await _client
        .from('exercise_masters')
        .update({'name': name})
        .eq('exerciseId', exerciseId);
  }

  @override
  Future<void> delete(int exerciseId) async {
    await _client
        .from('exercise_masters')
        .delete()
        .eq('exerciseId', exerciseId);
  }

  @override
  Future<void> updateSortOrders(List<ExerciseMaster> exercises) async {
    // 1件ずつsortOrderを更新（件数が少ないので十分）
    for (var i = 0; i < exercises.length; i++) {
      await _client
          .from('exercise_masters')
          .update({'sortOrder': i})
          .eq('exerciseId', exercises[i].exerciseId);
    }
  }
}
