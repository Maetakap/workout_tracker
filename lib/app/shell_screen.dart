import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ShellScreen extends StatelessWidget {
  const ShellScreen({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();

    int currentIndex = 0;
    if (location.startsWith('/list')) {
      currentIndex = 1;
    } else if (location.startsWith('/exercise-master')) {
      currentIndex = 2;
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/input');
            case 1:
              context.go('/list');
            case 2:
              context.go('/exercise-master');
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.edit), label: '記録'),
          NavigationDestination(icon: Icon(Icons.list), label: '一覧'),
          NavigationDestination(icon: Icon(Icons.fitness_center), label: '種目'),
        ],
      ),
    );
  }
}
