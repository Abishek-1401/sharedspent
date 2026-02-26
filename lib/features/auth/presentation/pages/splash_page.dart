import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/auth_gate.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  // This function is what moves the app past the logo
  void _navigateToNext() async {
    // 1. Wait for 2.5 seconds to show the logo
    await Future.delayed(const Duration(milliseconds: 2500));
    
    if (!mounted) return;

    // 2. Navigate to AuthGate and REMOVE SplashPage from the history
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const AuthGate(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: 800.ms,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // Your brand Cream background
      backgroundColor: const Color(0xFFFDF4E3), 
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // LOGO ICON
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.home_work_rounded,
                color: Colors.white,
                size: 60,
              ),
            )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .scale(
              begin: const Offset(1, 1), 
              end: const Offset(1.1, 1.1), 
              duration: 1000.ms, 
              curve: Curves.easeInOut,
            ),

            const SizedBox(height: 24),

            // LOGO TEXT
            Text(
              'Cohabit.',
              style: theme.textTheme.displayLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontSize: 40,
              ),
            )
            .animate()
            .fadeIn(duration: 800.ms)
            .slideY(begin: 0.3, end: 0),
          ],
        ),
      ),
    );
  }
}