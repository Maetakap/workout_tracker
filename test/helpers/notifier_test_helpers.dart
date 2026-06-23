import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// テスト用のProviderContainerを生成し、テスト終了時に自動でdisposeする。
///
/// 非同期の後続処理（invalidate連鎖など）がdispose後に走ってエラーになるのを
/// 防ぐため、dispose前に短い待機を挟む。
ProviderContainer createContainer({List<Override> overrides = const []}) {
  final container = ProviderContainer(overrides: overrides);
  addTearDown(() async {
    // build()内の非同期処理やinvalidate連鎖を完了させてからdispose
    await Future.delayed(const Duration(milliseconds: 50));
    container.dispose();
  });
  return container;
}

/// build()内のmicrotask・非同期fetchの完了を待つ。
Future<void> settle() => Future.delayed(const Duration(milliseconds: 50));
