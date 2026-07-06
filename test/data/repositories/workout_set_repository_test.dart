import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/data/database/app_database.dart';
import 'package:workout_tracker/data/repositories/drift/drift_workout_session_repository.dart';
import 'package:workout_tracker/data/repositories/drift/drift_workout_set_repository.dart';
import 'package:workout_tracker/data/repositories/interface/set_input.dart';
import 'package:workout_tracker/data/repositories/interface/workout_session_repository.dart';
import 'package:workout_tracker/data/repositories/interface/workout_set_repository.dart';

import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late WorkoutSetRepository setRepo;
  late WorkoutSessionRepository sessionRepo;

  setUp(() {
    db = createTestDatabase();
    setRepo = DriftWorkoutSetRepository(db);
    sessionRepo = DriftWorkoutSessionRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  // SetInputを生成するヘルパー（sessionIdは複合メソッドが内部採番するため不要）
  SetInput makeSet({required int exerciseId, required int setOrder}) {
    return SetInput(
      exerciseId: exerciseId,
      setOrder: setOrder,
      weightKg: 60.0,
      reps: 10,
      rir: 2,
    );
  }

  group('WorkoutSetRepository', () {
    test('findBySessionId()はsetOrder昇順で返す', () async {
      final sessionId = await sessionRepo.createSessionWithSets(
        date: DateTime(2026, 6, 1),
        focusLevel: 3,
        sets: [
          makeSet(exerciseId: 1, setOrder: 2),
          makeSet(exerciseId: 1, setOrder: 0),
          makeSet(exerciseId: 1, setOrder: 1),
        ],
      );

      final sets = await setRepo.findBySessionId(sessionId);
      expect(sets.map((s) => s.setOrder).toList(), [0, 1, 2]);
    });

    test('deleteBySessionId()でセッションのセットが全削除される', () async {
      final sessionId = await sessionRepo.createSessionWithSets(
        date: DateTime(2026, 6, 1),
        focusLevel: 3,
        sets: [makeSet(exerciseId: 1, setOrder: 0)],
      );

      await setRepo.deleteBySessionId(sessionId);

      final sets = await setRepo.findBySessionId(sessionId);
      expect(sets, isEmpty);
    });

    test('findAll()で全セッションのセットを取得できる', () async {
      await sessionRepo.createSessionWithSets(
        date: DateTime(2026, 6, 1),
        focusLevel: 3,
        sets: [makeSet(exerciseId: 1, setOrder: 0)],
      );
      await sessionRepo.createSessionWithSets(
        date: DateTime(2026, 6, 2),
        focusLevel: 3,
        sets: [makeSet(exerciseId: 2, setOrder: 0)],
      );

      final all = await setRepo.findAll();
      expect(all.length, 2);
    });
  });

  group('WorkoutSessionRepository 複合メソッド', () {
    test('createSessionWithSets()でセッションとセットが保存される', () async {
      final sessionId = await sessionRepo.createSessionWithSets(
        date: DateTime(2026, 6, 1),
        focusLevel: 4,
        memo: 'テスト',
        sets: [
          makeSet(exerciseId: 1, setOrder: 0),
          makeSet(exerciseId: 1, setOrder: 1),
        ],
      );

      final session = await sessionRepo.findById(sessionId);
      expect(session, isNotNull);
      expect(session!.focusLevel, 4);
      expect(session.memo, 'テスト');

      final sets = await setRepo.findBySessionId(sessionId);
      expect(sets.length, 2);
    });

    test('updateSessionWithSets()でセッションが更新されセットが全置換される', () async {
      // 最初に2セットで作成
      final sessionId = await sessionRepo.createSessionWithSets(
        date: DateTime(2026, 6, 1),
        focusLevel: 3,
        memo: 'before',
        sets: [
          makeSet(exerciseId: 1, setOrder: 0),
          makeSet(exerciseId: 1, setOrder: 1),
        ],
      );

      // 1セットに置き換え＋セッション情報も更新
      await sessionRepo.updateSessionWithSets(
        sessionId: sessionId,
        date: DateTime(2026, 6, 1),
        focusLevel: 5,
        memo: 'after',
        sets: [makeSet(exerciseId: 2, setOrder: 0)],
      );

      // セッションが更新されている
      final session = await sessionRepo.findById(sessionId);
      expect(session!.focusLevel, 5);
      expect(session.memo, 'after');

      // セットが全置換されている（2件→1件、exerciseId=2）
      final sets = await setRepo.findBySessionId(sessionId);
      expect(sets.length, 1);
      expect(sets.first.exerciseId, 2);
    });
  });
}
