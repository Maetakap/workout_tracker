import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/data/database/app_database.dart';
import 'package:workout_tracker/data/repositories/drift/drift_workout_session_repository.dart';
import 'package:workout_tracker/data/repositories/interface/workout_session_repository.dart';
import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late WorkoutSessionRepository repo;

  setUp(() {
    db = createTestDatabase();
    repo = DriftWorkoutSessionRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('WorkoutSessionRepository', () {
    test('insert()で追加しfindById()で取得できる', () async {
      final id = await repo.insert(
        date: DateTime(2026, 6, 1),
        focusLevel: 4,
        memo: 'テスト',
      );

      final session = await repo.findById(id);
      expect(session, isNotNull);
      expect(session!.focusLevel, 4);
      expect(session.memo, 'テスト');
    });

    test('memoなしで保存するとnullになる', () async {
      final id = await repo.insert(date: DateTime(2026, 6, 1), focusLevel: 3);
      final session = await repo.findById(id);
      expect(session!.memo, null);
    });

    test('findAll()は日付の降順で返す', () async {
      await repo.insert(date: DateTime(2026, 5, 1), focusLevel: 3);
      await repo.insert(date: DateTime(2026, 6, 1), focusLevel: 3);
      await repo.insert(date: DateTime(2026, 4, 1), focusLevel: 3);

      final all = await repo.findAll();
      expect(all.map((s) => s.date.month).toList(), [6, 5, 4]);
    });

    test('update()で更新される', () async {
      final id = await repo.insert(
        date: DateTime(2026, 6, 1),
        focusLevel: 3,
        memo: 'before',
      );

      await repo.update(
        sessionId: id,
        date: DateTime(2026, 6, 1),
        focusLevel: 5,
        memo: 'after',
      );

      final session = await repo.findById(id);
      expect(session!.focusLevel, 5);
      expect(session.memo, 'after');
    });

    test('delete()で削除される', () async {
      final id = await repo.insert(date: DateTime(2026, 6, 1), focusLevel: 3);
      await repo.delete(id);

      final session = await repo.findById(id);
      expect(session, isNull);
    });

    test('存在しないIDのfindById()はnullを返す', () async {
      final session = await repo.findById(999);
      expect(session, isNull);
    });
  });
}
