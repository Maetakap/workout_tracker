import '../../data/database/app_database.dart';
import '../shared/workout_math.dart';

class WorkoutListState {
  final List<WorkoutSession> sessions;
  final List<WorkoutSet> sets; // 種目フィルター用に全セットを保持
  final List<ExerciseMaster> exercises; // 種目名表示・フィルター用
  final int? selectedMonth; // yyyyMM形式（例：202606）
  final int? selectedExerciseId;
  final bool isLoading;

  const WorkoutListState({
    this.sessions = const [],
    this.sets = const [],
    this.exercises = const [],
    this.selectedMonth,
    this.selectedExerciseId,
    this.isLoading = false,
  });

  /// セッションに紐づく種目ごとの（種目名, 合計ボリューム）一覧を返す（表示用）
  List<(String, double)> exerciseSummariesForSession(int sessionId) {
    final sessionSets = sets.where((s) => s.sessionId == sessionId);
    final exerciseIds = sessionSets.map((s) => s.exerciseId).toSet();

    return exerciseIds.map((id) {
      final name = exercises
          .firstWhere(
            (e) => e.exerciseId == id,
            orElse: () => ExerciseMaster(
              exerciseId: -1,
              name: '(削除済み種目)',
              sortOrder: -1,
              createdAt: DateTime(0),
            ),
          )
          .name;

      final volume = sumVolume(
        sessionSets
            .where((s) => s.exerciseId == id)
            .map((s) => (s.weightKg, s.reps)),
      );

      return (name, volume);
    }).toList();
  }

  /// フィルター適用済みセッション一覧
  List<WorkoutSession> get filteredSessions {
    return sessions.where((session) {
      if (selectedMonth != null) {
        final month = session.date.year * 100 + session.date.month;
        if (month != selectedMonth) return false;
      }
      if (selectedExerciseId != null) {
        final hasExercise = sets.any(
          (s) =>
              s.sessionId == session.sessionId &&
              s.exerciseId == selectedExerciseId,
        );
        if (!hasExercise) return false;
      }
      return true;
    }).toList();
  }

  /// 月フィルター用の選択肢（セッションから生成）
  List<int> get availableMonths {
    return sessions
        .map((s) => s.date.year * 100 + s.date.month)
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
  }

  WorkoutListState copyWith({
    List<WorkoutSession>? sessions,
    List<WorkoutSet>? sets,
    List<ExerciseMaster>? exercises,
    int? selectedMonth,
    int? selectedExerciseId,
    bool? isLoading,
    bool clearMonth = false,
    bool clearExercise = false,
  }) {
    return WorkoutListState(
      sessions: sessions ?? this.sessions,
      sets: sets ?? this.sets,
      exercises: exercises ?? this.exercises,
      selectedMonth: clearMonth ? null : selectedMonth ?? this.selectedMonth,
      selectedExerciseId: clearExercise
          ? null
          : selectedExerciseId ?? this.selectedExerciseId,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
