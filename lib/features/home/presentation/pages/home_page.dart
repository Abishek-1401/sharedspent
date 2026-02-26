import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:rive/rive.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/neo_bento_widgets.dart';

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
    final avatarUrl =
        _profileData?['avatar_url'] ?? 'https://via.placeholder.com/150';
    final username = _profileData?['username'] ?? 'Roomie';

    return Scaffold(
      body: NeoBentoBackground(
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(
                'Cohabit',
                style: theme.textTheme.titleLarge,
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () =>
                      Supabase.instance.client.auth.signOut(),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroCard(
                      context,
                      avatarUrl: avatarUrl,
                      username: username,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Today in your home",
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 12),
                    _buildBentoGrid(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('More sections coming soon ✨'),
              behavior: SnackBarBehavior.floating,
              margin: _snackMargin(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          );
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.checklist_rounded),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.cookie_rounded),
            label: 'Pantry',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_rounded),
            label: 'Roomies',
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(
    BuildContext context, {
    required String avatarUrl,
    required String username,
  }) {
    final theme = Theme.of(context);

    return SquishyCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundImage: NetworkImage(avatarUrl),
          )
              .animate()
              .scale(duration: 600.ms, curve: Curves.easeOutBack),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome home,",
                  style: theme.textTheme.bodyMedium,
                ),
                Text(
                  username,
                  style: theme.textTheme.titleLarge,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "Shared chores feeling balanced today.",
                        style: theme.textTheme.labelMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            height: 60,
            child: const RiveAnimation.network(
              'https://public.rive.app/community/runtime-files/2300-4676-firey-icons.riv',
              fit: BoxFit.contain,
            ),
          ).animate().fadeIn(duration: 700.ms),
        ],
      ),
    );
  }

  Widget _buildBentoGrid(BuildContext context) {
    final theme = Theme.of(context);

    final tiles = [
      _BentoTileData(
        title: 'Chores',
        subtitle: '3 due today',
        icon: Icons.check_circle_rounded,
        color: AppColors.accentMint,
      ),
      _BentoTileData(
        title: 'Pantry',
        subtitle: 'Top up snacks',
        icon: Icons.kitchen_rounded,
        color: AppColors.accentYellow,
      ),
      _BentoTileData(
        title: 'Bills',
        subtitle: 'Next in 5 days',
        icon: Icons.account_balance_wallet_rounded,
        color: AppColors.accentPink,
      ),
      _BentoTileData(
        title: 'Mood board',
        subtitle: 'How’s everyone feeling?',
        icon: Icons.emoji_emotions_rounded,
        color: AppColors.accentBlue,
      ),
    ];

    return AlignedGridView.count(
      crossAxisCount: 2,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      itemCount: tiles.length,
      itemBuilder: (context, index) {
        final data = tiles[index];
        final animationDelay = (150 + (index * 80)).ms;

        return GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${data.title} is on the roadmap ✨'),
                behavior: SnackBarBehavior.floating,
                margin: _snackMargin(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.outlineSoft,
                width: 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: data.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    data.icon,
                    color: data.color,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  data.title,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  data.subtitle,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(delay: animationDelay, duration: 350.ms)
              .slideY(begin: 0.12, end: 0),
        );
      },
    );
  }

  EdgeInsets _snackMargin(BuildContext context) {
    final padding = MediaQuery.of(context).viewPadding;
    final bottom = 16.0 + padding.bottom + kBottomNavigationBarHeight;
    return EdgeInsets.fromLTRB(16, 0, 16, bottom);
  }
}

class _BentoTileData {
  _BentoTileData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
}
