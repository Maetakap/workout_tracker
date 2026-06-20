import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/workout_input/workout_input_screen.dart';
import '../features/workout_list/workout_list_screen.dart';
import '../features/workout_detail/workout_detail_screen.dart';
import '../features/workout_edit/workout_edit_screen.dart';
import '../features/exercise_master/exercise_master_screen.dart';
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
  routes: [
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
