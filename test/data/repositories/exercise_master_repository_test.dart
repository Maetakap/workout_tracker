import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/data/database/app_database.dart';
import 'package:workout_tracker/data/repositories/drift/drift_exercise_master_repository.dart';
import 'package:workout_tracker/data/repositories/interface/exercise_master_repository.dart';

import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late ExerciseMasterRepository repo;

  setUp(() {
    db = createTestDatabase();
    repo = DriftExerciseMasterRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('ExerciseMasterRepository', () {
    test('insert()で追加しfindAll()で取得できる', () async {
      await repo.insert('ベンチプレス', 0);
      final all = await repo.findAll();
      expect(all.length, 1);
      expect(all.first.name, 'ベンチプレス');
    });

    test('findAll()はsortOrder昇順で返す', () async {
      await repo.insert('スクワット', 2);
      await repo.insert('ベンチプレス', 0);
      await repo.insert('デッドリフト', 1);

      final all = await repo.findAll();
      expect(all.map((e) => e.name).toList(), ['ベンチプレス', 'デッドリフト', 'スクワット']);
    });

    test('updateName()で名前が更新される', () async {
      final id = await repo.insert('ベンチプレス', 0);
      await repo.updateName(id, 'インクラインベンチプレス');

      final all = await repo.findAll();
      expect(all.first.name, 'インクラインベンチプレス');
    });

    test('delete()で削除される', () async {
      final id = await repo.insert('ベンチプレス', 0);
      await repo.delete(id);

      final all = await repo.findAll();
      expect(all, isEmpty);
    });

    test('updateSortOrders()で並び順が一括更新される', () async {
      final id1 = await repo.insert('ベンチプレス', 0);
      final id2 = await repo.insert('スクワット', 1);

      // 取得して順序を入れ替えて渡す
      final all = await repo.findAll();
      final reordered = [all[1], all[0]]; // スクワット, ベンチプレス
      await repo.updateSortOrders(reordered);

      final result = await repo.findAll();
      expect(result.first.exerciseId, id2); // スクワットが先頭
      expect(result.last.exerciseId, id1);
    });
  });
}
