import '../../database/app_database.dart';

/// 種目マスタRepositoryのインターフェース
abstract interface class ExerciseMasterRepository {
  Future<List<ExerciseMaster>> findAll();
  Future<int> insert(String name, int sortOrder);
  Future<void> updateName(int exerciseId, String name);
  Future<void> delete(int exerciseId);
  Future<void> updateSortOrders(List<ExerciseMaster> exercises);
}
