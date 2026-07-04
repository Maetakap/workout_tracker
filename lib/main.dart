import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Web版のみSupabaseを初期化（AndroidはローカルDriftのため不要）
  if (kIsWeb) {
    await Supabase.initialize(
      url: const String.fromEnvironment('SUPABASE_URL'),
      publishableKey: const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY '),
    );
  }

  runApp(const ProviderScope(child: WorkoutTrackerApp()));
}

class WorkoutTrackerApp extends ConsumerWidget {
  const WorkoutTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: '筋トレ記録',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ja')],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
        fontFamily: 'LINE Seed JP',
        fontFamilyFallback: const [
          'Noto Sans JP',
          'Hiragino Sans',
          'sans-serif',
        ],
      ),
      routerConfig: router,
    );
  }
}
