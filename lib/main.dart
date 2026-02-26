import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants.dart';
import 'core/theme/app_theme.dart';
// 1. Import your new SplashPage
import 'features/auth/presentation/pages/splash_page.dart'; 

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: Constants.supabaseUrl,
    anonKey: Constants.supabaseAnonKey,
  );

  runApp(const CohabitApp());
}

class CohabitApp extends StatelessWidget {
  const CohabitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cohabit',
      debugShowCheckedModeBanner: false,
      
      // APPLY THEMES HERE
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, 
      
      // 2. Change AuthGate() to SplashPage()
      // The SplashPage will handle navigating to AuthGate after its animation
      home: const SplashPage(), 
    );
  }
}