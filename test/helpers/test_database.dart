import 'package:drift/native.dart';
import 'package:workout_tracker/data/database/app_database.dart';

/// インメモリDBのAppDatabaseを生成する。
/// テストごとに独立したDBになるので、テスト間でデータが共有されない。
AppDatabase createTestDatabase() {
  return AppDatabase.forTesting(NativeDatabase.memory());
}
