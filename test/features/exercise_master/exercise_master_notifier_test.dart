import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:workout_tracker/data/repositories/exercise_master_repository.dart';
import 'package:workout_tracker/data/providers.dart';
import 'package:workout_tracker/features/exercise_master/exercise_master_notifier.dart';
import 'package:workout_tracker/data/database/app_database.dart';

import 'exercise_master_notifier_test.mocks.dart';

@GenerateMocks([ExerciseMasterRepository])
void main() {
  late MockExerciseMasterRepository mockRepo;
  late ProviderContainer container;

  /// テスト用のExerciseMasterを生成するヘルパー
  ExerciseMaster makeExercise({
    required int id,
    required String name,
    int sortOrder = 0,
  }) {
    return ExerciseMaster(
      exerciseId: id,
      name: name,
      sortOrder: sortOrder,
      createdAt: DateTime(2026, 1, 1),
    );
  }

  setUp(() {
    mockRepo = MockExerciseMasterRepository();
    container = ProviderContainer(
      overrides: [exerciseMasterRepositoryProvider.overrideWithValue(mockRepo)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('ExerciseMasterNotifier', () {
    test('1. 初期状態：exercisesが空・isLoadingがfalse', () {
      // findAllが空リストを返すよう設定
      when(mockRepo.findAll()).thenAnswer((_) async => []);

      final state = container.read(exerciseMasterProvider);
      expect(state.exercises, isEmpty);
      expect(state.isLoading, false);
    });

    test('2. addExercise()：1件追加後にexercisesに反映される', () async {
      final exercise = makeExercise(id: 1, name: 'ベンチプレス');
      when(mockRepo.findAll()).thenAnswer((_) async => [exercise]);
      when(mockRepo.insert(any, any)).thenAnswer((_) async => 1);

      await container
          .read(exerciseMasterProvider.notifier)
          .addExercise('ベンチプレス');

      final state = container.read(exerciseMasterProvider);
      expect(state.exercises.length, 1);
      expect(state.exercises.first.name, 'ベンチプレス');
    });

    test('3. deleteExercise()：削除後にexercisesが空になる', () async {
      // 削除後のfindAllは空を返す
      when(mockRepo.findAll()).thenAnswer((_) async => []);
      when(mockRepo.insert(any, any)).thenAnswer((_) async => 1);
      when(mockRepo.delete(any)).thenAnswer((_) async {});

      await container
          .read(exerciseMasterProvider.notifier)
          .addExercise('ベンチプレス');

      // deleteの後はfindAllが空を返すよう上書き
      when(mockRepo.findAll()).thenAnswer((_) async => []);
      await container.read(exerciseMasterProvider.notifier).deleteExercise(1);

      final state = container.read(exerciseMasterProvider);
      expect(state.exercises, isEmpty);
    });

    test('4. updateName()：名前更新後に反映される', () async {
      final updated = makeExercise(id: 1, name: 'スクワット');
      when(mockRepo.updateName(any, any)).thenAnswer((_) async {});
      when(mockRepo.findAll()).thenAnswer((_) async => [updated]);

      await container
          .read(exerciseMasterProvider.notifier)
          .updateName(1, 'スクワット');

      final state = container.read(exerciseMasterProvider);
      expect(state.exercises.first.name, 'スクワット');
    });

    test('5. reorder()：並び替え後にリストの順序が変わる', () async {
      final e1 = makeExercise(id: 1, name: 'ベンチプレス', sortOrder: 0);
      final e2 = makeExercise(id: 2, name: 'スクワット', sortOrder: 1);

      when(mockRepo.insert(any, any)).thenAnswer((_) async => 1);
      when(mockRepo.updateSortOrders(any)).thenAnswer((_) async {});

      // 1件目追加
      when(mockRepo.findAll()).thenAnswer((_) async => [e1]);
      await container
          .read(exerciseMasterProvider.notifier)
          .addExercise('ベンチプレス');

      // 2件目追加
      when(mockRepo.findAll()).thenAnswer((_) async => [e1, e2]);
      await container
          .read(exerciseMasterProvider.notifier)
          .addExercise('スクワット');

      expect(container.read(exerciseMasterProvider).exercises.length, 2);

      // oldIndex=0をnewIndex=2に移動（Notifier内でnewIndex--→index=1）
      await container.read(exerciseMasterProvider.notifier).reorder(0, 2);

      final state = container.read(exerciseMasterProvider);
      expect(state.exercises.first.name, 'スクワット');
    });

    test('6. addExercise() Repository失敗時：exercisesが変化しない', () async {
      when(mockRepo.findAll()).thenAnswer((_) async => []);
      when(mockRepo.insert(any, any)).thenThrow(Exception('DB error'));

      expect(
        () => container
            .read(exerciseMasterProvider.notifier)
            .addExercise('ベンチプレス'),
        throwsException,
      );

      final state = container.read(exerciseMasterProvider);
      expect(state.exercises, isEmpty);
    });
  });
}
