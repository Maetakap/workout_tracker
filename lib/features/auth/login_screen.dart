import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('筋トレ記録', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Googleアカウントでログインしてください',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.login),
              label: const Text('Googleでログイン'),
              onPressed: () async {
                await Supabase.instance.client.auth.signInWithOAuth(
                  OAuthProvider.google,
                  redirectTo: kIsWeb ? _resolveRedirectTo() : null,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

String _resolveRedirectTo() {
  final base = Uri.base;
  if (base.host == 'maetakap.github.io') {
    // 本番：ベースパス固定
    return '${base.origin}/workout_tracker/';
  }
  // ローカル開発：オリジンのみ
  return base.origin;
}
