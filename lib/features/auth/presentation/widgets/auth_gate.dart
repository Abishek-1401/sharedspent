import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../pages/login_page.dart';
import '../pages/profile_setup_page.dart';
import '../../../home/presentation/pages/home_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    // LISTEN FOR EVENTS: This clears the "stuck" pages automatically
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        // This removes any pages (like SignUp or ForgotPassword) 
        // that were pushed on top of the AuthGate
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session;

        // 1. Show Login if no session
        if (session == null) {
          return const LoginPage();
        }

        // 2. User is authenticated, check their Profile data in real-time
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: Supabase.instance.client
              .from('profiles')
              .stream(primaryKey: ['id'])
              .eq('id', session.user.id),
          builder: (context, profileSnapshot) {
            // Loading state for the DB check
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // Handle missing profile (should be created by your SQL trigger) 
            if (!profileSnapshot.hasData || profileSnapshot.data!.isEmpty) {
              return const Scaffold(
                body: Center(child: Text("Creating your home...")),
              );
            }

            final profile = profileSnapshot.data!.first;
            
            // 3. FORCE SETUP: If username is null/empty, show ProfileSetupPage
            if (profile['username'] == null || (profile['username'] as String).isEmpty) {
              return const ProfileSetupPage();
            }

            // 4. HOME: Success! Show the main app [cite: 54, 57]
            return const HomePage();
          },
        );
      },
    );
  }
}