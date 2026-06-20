import 'package:drift/drift.dart';

/// 種目マスタテーブル
class ExerciseMasters extends Table {
  IntColumn get exerciseId => integer().autoIncrement()();
  TextColumn get name => text().withLength(max: 30)();
  IntColumn get sortOrder => integer()();
  DateTimeColumn get createdAt => dateTime()();
}

/// トレーニングセッションテーブル
class WorkoutSessions extends Table {
  IntColumn get sessionId => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  IntColumn get focusLevel => integer()();
  TextColumn get memo => text().withLength(max: 200).nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

/// セットテーブル
class WorkoutSets extends Table {
  IntColumn get setId => integer().autoIncrement()();
  IntColumn get sessionId =>
      integer().references(WorkoutSessions, #sessionId)();
  IntColumn get exerciseId =>
      integer().references(ExerciseMasters, #exerciseId)();
  IntColumn get setOrder => integer()();
  RealColumn get weightKg => real()();
  IntColumn get reps => integer()();
  IntColumn get rir => integer()();
  DateTimeColumn get createdAt => dateTime()();
}
