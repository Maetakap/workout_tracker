import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/workout_input/workout_input_screen.dart';
import '../features/workout_list/workout_list_screen.dart';
import '../features/workout_detail/workout_detail_screen.dart';
import '../features/workout_edit/workout_edit_screen.dart';
import '../features/exercise_master/exercise_master_screen.dart';
import '../features/auth/login_screen.dart';
import 'shell_screen.dart';

CustomTransitionPage<T> _fadePage<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

final router = GoRouter(
  initialLocation: '/input',
  // Web版のみ、Supabaseの認証状態変化を監視して自動リダイレクト
  refreshListenable: kIsWeb ? _AuthNotifier() : null,
  redirect: (context, state) {
    // Android版はログイン概念なし → 分岐しない
    if (!kIsWeb) return null;

    final loggedIn = Supabase.instance.client.auth.currentUser != null;
    final loggingIn = state.matchedLocation == '/login';

    // 未ログインでログイン画面以外にいる → /login へ
    if (!loggedIn && !loggingIn) return '/login';
    // ログイン済みでログイン画面にいる → メインへ
    if (loggedIn && loggingIn) return '/input';
    // それ以外はそのまま
    return null;
  },
  routes: [
    // ログイン画面（ShellRouteの外・BottomNav無し）
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) =>
          _fadePage(context: context, state: state, child: const LoginScreen()),
    ),
    ShellRoute(
      builder: (context, state, child) => ShellScreen(child: child),
      routes: [
        GoRoute(
          path: '/input',
          pageBuilder: (context, state) => _fadePage(
            context: context,
            state: state,
            child: const WorkoutInputScreen(),
          ),
        ),
        GoRoute(
          path: '/list',
          pageBuilder: (context, state) => _fadePage(
            context: context,
            state: state,
            child: const WorkoutListScreen(),
          ),
          routes: [
            GoRoute(
              path: 'detail/:id',
              pageBuilder: (context, state) => _fadePage(
                context: context,
                state: state,
                child: WorkoutDetailScreen(
                  sessionId: int.parse(state.pathParameters['id']!),
                ),
              ),
              routes: [
                GoRoute(
                  path: 'edit',
                  pageBuilder: (context, state) => _fadePage(
                    context: context,
                    state: state,
                    child: WorkoutEditScreen(
                      sessionId: int.parse(state.pathParameters['id']!),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/exercise-master',
          pageBuilder: (context, state) => _fadePage(
            context: context,
            state: state,
            child: const ExerciseMasterScreen(),
          ),
        ),
      ],
    ),
  ],
);

// Supabaseの認証状態変化をGoRouterに伝えるためのListenable
class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier() {
    _sub = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<AuthState> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
