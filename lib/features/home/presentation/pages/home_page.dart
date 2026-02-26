import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final user = Supabase.instance.client.auth.currentUser;
  Map<String, dynamic>? _profileData;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    if (user == null) return;
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user!.id)
          .single();
      setState(() {
        _profileData = data;
      });
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatarUrl = _profileData?['avatar_url'] ?? 'https://via.placeholder.com/150';
    final username = _profileData?['username'] ?? 'Roomie';

    return Scaffold(
      appBar: AppBar(
        title: Text('Cohabit.', style: theme.textTheme.displayMedium?.copyWith(fontSize: 20)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Supabase.instance.client.auth.signOut(),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // WELCOME BENTO CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(avatarUrl),
                  ).animate().scale(),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Welcome back,", 
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary.withValues(alpha: 0.7) // FIXED DEPRECATION
                        )
                      ),
                      Text(
                        username, 
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary, 
                          fontSize: 22, 
                          fontWeight: FontWeight.bold
                        )
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().slideY(begin: 0.2, end: 0),

            const SizedBox(height: 24),
            Text("Your Household", style: theme.textTheme.bodyLarge),
            const SizedBox(height: 12),

            // DUMMY BENTO GRID
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Icon(Icons.kitchen, color: theme.colorScheme.primary),
                          const SizedBox(height: 8),
                          const Text("Pantry"),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Icon(Icons.account_balance_wallet, color: theme.colorScheme.primary),
                          const SizedBox(height: 8),
                          const Text("Expenses"),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}