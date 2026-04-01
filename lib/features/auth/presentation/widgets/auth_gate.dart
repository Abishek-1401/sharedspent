import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../pages/login_page.dart';
import '../pages/profile_setup_page.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../../home/presentation/pages/room_setup_page.dart';

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

  // Helper to ensure the profile row exists
  // We use .upsert with ON CONFLICT DO NOTHING (id is PK)
  final Set<String> _profileCheckCompleted = {};
  Future<void> _ensureProfileExists(String userId) async {
    if (_profileCheckCompleted.contains(userId)) return;
    try {
      await Supabase.instance.client.from('profiles').upsert({
        'id': userId,
      }, onConflict: 'id');
      _profileCheckCompleted.add(userId);
    } catch (e) {
      debugPrint("AuthGate: Error ensuring profile exists: $e");
    }
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
            if (profileSnapshot.connectionState == ConnectionState.waiting && !profileSnapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // Error state ONLY if we don't have data already. 
            // This suppresses RealtimeSubscriptionException popups/screens when a connection drops but we already loaded the app.
            if (profileSnapshot.hasError && (!profileSnapshot.hasData || profileSnapshot.data!.isEmpty)) {
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off_rounded, color: Colors.orange, size: 48),
                      const SizedBox(height: 16),
                      Text("Connection Error: ${profileSnapshot.error.toString()}"),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => setState(() {}),
                        child: const Text("Retry"),
                      ),
                    ],
                  ),
                ),
              );
            }

            // --- AUTO-CREATE PROFILE IF MISSING ---
            if (!profileSnapshot.hasData || profileSnapshot.data!.isEmpty) {
              // We trigger a one-time create if the profile is missing
              // This prevents being "stuck" if the SQL trigger didn't run
              _ensureProfileExists(session.user.id);
              
              return const Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text("Creating your home profile..."),
                    ],
                  ),
                ),
              );
            }

            final profile = profileSnapshot.data!.first;
            
            // 3. FORCE SETUP: If username is null/empty, show ProfileSetupPage
            if (profile['username'] == null || (profile['username'] as String).isEmpty) {
              return const ProfileSetupPage();
            }

            // 4. ROOM SETUP: If apartment_id is null, show RoomSetupPage
            if (profile['apartment_id'] == null) {
              return const RoomSetupPage();
            }

            // 5. HOME: Success! Show the main app [cite: 54, 57]
            return const HomePage();
          },
        );
      },
    );
  }
}