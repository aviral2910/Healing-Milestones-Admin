import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_palette.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(
    const ProviderScope(
      child: HealingMilestonesAdminApp(),
    ),
  );
}

class HealingMilestonesAdminApp extends ConsumerWidget {
  const HealingMilestonesAdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: 'Healing Milestones Admin',
      // Switch back to the beautiful Golden Dark theme but keeping Material 3
      theme: AppTheme.getThemeData(ThemePalette.goldenLight),
      darkTheme: AppTheme.getThemeData(ThemePalette.goldenDark),
      themeMode: ThemeMode.dark, 
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
