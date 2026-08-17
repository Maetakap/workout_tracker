import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// DateField追加などで縦に伸びた画面用に、テストのビューポートを広げる。
/// デフォルトの800x600だとListView内の後続ウィジェットが
/// 可視領域外になり構築されない（find.textが0件になる）ことがあるため。
void useTallTestViewport(
  WidgetTester tester, {
  Size size = const Size(400, 1400),
}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// GoRouterとProvider overridesを渡してMaterialApp.routerをpumpする共通処理。
Future<void> pumpRoutedScreen(
  WidgetTester tester, {
  required GoRouter router,
  required List<Override> overrides,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pump();
}
