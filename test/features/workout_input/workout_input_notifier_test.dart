import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:workout_tracker/data/providers.dart';
import 'package:workout_tracker/data/repositories/exercise_master_repository.dart';
import 'package:workout_tracker/data/repositories/workout_session_repository.dart';
import 'package:workout_tracker/data/repositories/workout_set_repository.dart';
import 'package:workout_tracker/features/workout_input/workout_input_notifier.dart';
import 'package:workout_tracker/features/workout_input/workout_input_state.dart';
import 'package:workout_tracker/features/workout_list/workout_list_notifier.dart';

import 'workout_input_notifier_test.mocks.dart';

@GenerateMocks([
  WorkoutSessionRepository,
  WorkoutSetRepository,
  ExerciseMasterRepository,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockWorkoutSessionRepository mockSessionRepo;
  late MockWorkoutSetRepository mockSetRepo;
  late MockExerciseMasterRepository mockExerciseRepo;
  late ProviderContainer container;

  setUp(() {
    mockSessionRepo = MockWorkoutSessionRepository();
    mockSetRepo = MockWorkoutSetRepository();
    mockExerciseRepo = MockExerciseMasterRepository();

    when(mockExerciseRepo.findAll()).thenAnswer((_) async => []);
    when(mockSetRepo.findAll()).thenAnswer((_) async => []);
    when(mockSessionRepo.findAll()).thenAnswer((_) async => []);

    container = ProviderContainer(
      overrides: [
        workoutSessionRepositoryProvider.overrideWithValue(mockSessionRepo),
        workoutSetRepositoryProvider.overrideWithValue(mockSetRepo),
        exerciseMasterRepositoryProvider.overrideWithValue(mockExerciseRepo),
      ],
    );
    // workoutListProviderを購読してinvalidate後のエラーを吸収
    container.listen(workoutListProvider, (_, _) {}, onError: (_, _) {});
    // tearDownをsetUp内でaddTearDownとして登録
    addTearDown(() async {
      await Future.microtask(() {});
      container.dispose();
    });
  });

  WorkoutInputNotifier notifier() =>
      container.read(workoutInputProvider.notifier);

  WorkoutInputState currentState() => container.read(workoutInputProvider);

  group('WorkoutInputNotifier', () {
    test('1. 初期状態：exerciseCards1件・focusLevelがnull・isSavingがfalse', () {
      expect(currentState().exerciseCards.length, 1);
      expect(currentState().focusLevel, null);
      expect(currentState().isSaving, false);
    });

    test('2. addExerciseCard()：カードが1件増える', () {
      notifier().addExerciseCard();
      expect(currentState().exerciseCards.length, 2);
    });

    test('3. removeExerciseCard() 2枚以上：指定カードが削除される', () {
      notifier().addExerciseCard();
      expect(currentState().exerciseCards.length, 2);
      notifier().removeExerciseCard(0);
      expect(currentState().exerciseCards.length, 1);
    });

    test('4. removeExerciseCard() 1枚のみ：削除されない', () {
      notifier().removeExerciseCard(0);
      expect(currentState().exerciseCards.length, 1);
    });

    test('5. addSet()：対象カードのセットが1件増え、前セットのweightKgのみコピーされる', () {
      notifier().updateWeight(0, 0, 60.0);
      notifier().updateReps(0, 0, 10);
      notifier().updateRir(0, 0, 2);
      notifier().addSet(0);

      final sets = currentState().exerciseCards[0].sets;
      expect(sets.length, 2);
      expect(sets[1].weightKg, 60.0);
      expect(sets[1].reps, null);
      expect(sets[1].rir, null);
    });

    test('6. removeSet() 2件以上：指定セットが削除される', () {
      notifier().addSet(0);
      expect(currentState().exerciseCards[0].sets.length, 2);
      notifier().removeSet(0, 0);
      expect(currentState().exerciseCards[0].sets.length, 1);
    });

    test('7. removeSet() 1件のみ：削除されない', () {
      notifier().removeSet(0, 0);
      expect(currentState().exerciseCards[0].sets.length, 1);
    });

    test('8. updateWeight()：指定カード・指定セットのweightKgのみ更新される', () {
      notifier().addSet(0);
      notifier().updateWeight(0, 0, 80.0);
      expect(currentState().exerciseCards[0].sets[0].weightKg, 80.0);
      expect(currentState().exerciseCards[0].sets[1].weightKg, null);
    });

    test('9. updateReps()：指定セットのrepsが更新される', () {
      notifier().updateReps(0, 0, 12);
      expect(currentState().exerciseCards[0].sets[0].reps, 12);
    });

    test('10. updateRir()：指定セットのrirが更新される', () {
      notifier().updateRir(0, 0, 3);
      expect(currentState().exerciseCards[0].sets[0].rir, 3);
    });

    test('11. setFocusLevel()：focusLevelが更新される', () {
      notifier().setFocusLevel(4);
      expect(currentState().focusLevel, 4);
    });

    test('12. setMemo()：memoが更新される', () {
      notifier().setMemo('テストメモ');
      expect(currentState().memo, 'テストメモ');
    });

    test('13. saveSession() 成功：isSavingがfalseに戻り状態がリセットされる', () async {
      notifier().setExerciseId(0, 1);
      notifier().updateWeight(0, 0, 60.0);
      notifier().updateReps(0, 0, 10);
      notifier().updateRir(0, 0, 2);
      notifier().setFocusLevel(3);

      when(
        mockSessionRepo.insert(
          date: anyNamed('date'),
          focusLevel: anyNamed('focusLevel'),
          memo: anyNamed('memo'),
        ),
      ).thenAnswer((_) async => 1);
      when(mockSetRepo.insertAll(any)).thenAnswer((_) async {});
      // findAllはinvalidate後に呼ばれるのでスタブを設定
      when(mockSessionRepo.findAll()).thenAnswer((_) async => []);
      when(mockSetRepo.findAll()).thenAnswer((_) async => []);

      await notifier().saveSession();
      // 非同期の後続処理を完了させてからdisposeされるよう待つ
      await Future.delayed(const Duration(milliseconds: 100));

      expect(currentState().exerciseCards.length, 1);
      expect(currentState().focusLevel, null);
      expect(currentState().isSaving, false);
    });

    test('14. saveSession() Repository失敗時：isSavingがfalseに戻る', () async {
      notifier().setExerciseId(0, 1);
      notifier().updateWeight(0, 0, 60.0);
      notifier().updateReps(0, 0, 10);
      notifier().updateRir(0, 0, 2);
      notifier().setFocusLevel(3);

      when(
        mockSessionRepo.insert(
          date: anyNamed('date'),
          focusLevel: anyNamed('focusLevel'),
          memo: anyNamed('memo'),
        ),
      ).thenThrow(Exception('DB error'));

      try {
        await notifier().saveSession();
      } catch (_) {}

      expect(currentState().isSaving, false);
    });
  });
}
