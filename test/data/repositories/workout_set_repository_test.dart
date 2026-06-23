import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/data/database/app_database.dart';
import 'package:workout_tracker/data/repositories/workout_session_repository.dart';
import 'package:workout_tracker/data/repositories/workout_set_repository.dart';

import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late WorkoutSetRepository setRepo;
  late WorkoutSessionRepository sessionRepo;

  setUp(() {
    db = createTestDatabase();
    setRepo = WorkoutSetRepository(db);
    sessionRepo = WorkoutSessionRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  // セットを生成するヘルパー
  WorkoutSetsCompanion makeSet({
    required int sessionId,
    required int exerciseId,
    required int setOrder,
  }) {
    return WorkoutSetsCompanion.insert(
      sessionId: sessionId,
      exerciseId: exerciseId,
      setOrder: setOrder,
      weightKg: 60.0,
      reps: 10,
      rir: 2,
      createdAt: DateTime(2026, 1, 1),
    );
  }

  group('WorkoutSetRepository', () {
    test('insertAll()で複数セットが保存される', () async {
      final sessionId = await sessionRepo.insert(
        date: DateTime(2026, 6, 1),
        focusLevel: 3,
      );

      await setRepo.insertAll([
        makeSet(sessionId: sessionId, exerciseId: 1, setOrder: 0),
        makeSet(sessionId: sessionId, exerciseId: 1, setOrder: 1),
      ]);

      final sets = await setRepo.findBySessionId(sessionId);
      expect(sets.length, 2);
    });

    test('findBySessionId()はsetOrder昇順で返す', () async {
      final sessionId = await sessionRepo.insert(
        date: DateTime(2026, 6, 1),
        focusLevel: 3,
      );
      await setRepo.insertAll([
        makeSet(sessionId: sessionId, exerciseId: 1, setOrder: 2),
        makeSet(sessionId: sessionId, exerciseId: 1, setOrder: 0),
        makeSet(sessionId: sessionId, exerciseId: 1, setOrder: 1),
      ]);

      final sets = await setRepo.findBySessionId(sessionId);
      expect(sets.map((s) => s.setOrder).toList(), [0, 1, 2]);
    });

    test('replaceAll()で既存セットを削除して入れ替える', () async {
      final sessionId = await sessionRepo.insert(
        date: DateTime(2026, 6, 1),
        focusLevel: 3,
      );
      // 最初に2件
      await setRepo.insertAll([
        makeSet(sessionId: sessionId, exerciseId: 1, setOrder: 0),
        makeSet(sessionId: sessionId, exerciseId: 1, setOrder: 1),
      ]);

      // 1件に置き換え
      await setRepo.replaceAll(sessionId, [
        makeSet(sessionId: sessionId, exerciseId: 2, setOrder: 0),
      ]);

      final sets = await setRepo.findBySessionId(sessionId);
      expect(sets.length, 1);
      expect(sets.first.exerciseId, 2);
    });

    test('deleteBySessionId()でセッションのセットが全削除される', () async {
      final sessionId = await sessionRepo.insert(
        date: DateTime(2026, 6, 1),
        focusLevel: 3,
      );
      await setRepo.insertAll([
        makeSet(sessionId: sessionId, exerciseId: 1, setOrder: 0),
      ]);

      await setRepo.deleteBySessionId(sessionId);

      final sets = await setRepo.findBySessionId(sessionId);
      expect(sets, isEmpty);
    });

    test('findAll()で全セッションのセットを取得できる', () async {
      final s1 = await sessionRepo.insert(
        date: DateTime(2026, 6, 1),
        focusLevel: 3,
      );
      final s2 = await sessionRepo.insert(
        date: DateTime(2026, 6, 2),
        focusLevel: 3,
      );
      await setRepo.insertAll([
        makeSet(sessionId: s1, exerciseId: 1, setOrder: 0),
        makeSet(sessionId: s2, exerciseId: 2, setOrder: 0),
      ]);

      final all = await setRepo.findAll();
      expect(all.length, 2);
    });
  });
}
