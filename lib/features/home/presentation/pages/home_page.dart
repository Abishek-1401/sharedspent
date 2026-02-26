import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/neo_bento_widgets.dart';
import '../../../../main.dart';
import 'profile_settings_page.dart';

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
      final data = await Supabase.instance.client.from('profiles').select().eq('id', user!.id).single();
      if (mounted) {
        setState(() {
          _profileData = data;
        });
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    }
  }

  void _showProfileMenu() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => GlassSheet(
        title: 'Account & Settings',
        children: [
          _MenuTile(
            icon: Icons.person_outline_rounded,
            label: 'Edit Profile',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileSettingsPage())).then((_) => _fetchProfile());
            },
          ),
          _MenuTile(
            icon: themeNotifier.value == ThemeMode.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            label: 'Switch Theme',
            onTap: () {
              themeNotifier.value = themeNotifier.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
              Navigator.pop(context);
            },
          ),
          const Divider(height: 32, thickness: 1, indent: 16, endIndent: 16),
          _MenuTile(
            icon: Icons.logout_rounded,
            label: 'Logout',
            isDestructive: true,
            onTap: () {
              Navigator.pop(context);
              Supabase.instance.client.auth.signOut();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatarUrl = _profileData?['avatar_url'] ?? 'https://api.dicebear.com/7.x/avataaars/svg?seed=${user?.id}';
    final username = _profileData?['username'] ?? 'Roomie';

    return Scaffold(
      body: NeoBentoBackground(
        child: Stack(
          children: [
            Column(
              children: [
                // Top Nav
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        FittedBox(
                          child: Text(
                            'Cohabit',
                            style: theme.textTheme.titleLarge?.copyWith(fontSize: 24),
                          ),
                        ),
                        GestureDetector(
                          onTap: _showProfileMenu,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
                            ),
                            child: CircleAvatar(
                              radius: 20,
                              backgroundImage: NetworkImage(avatarUrl),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Main Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Welcome home,', style: theme.textTheme.bodyMedium),
                        FittedBox(
                          child: Text(username, style: theme.textTheme.displayMedium),
                        ),
                        const SizedBox(height: 32),
                        _buildStaggeredBentoGrid(),
                        const SizedBox(height: 100), // Space for bottom dock
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Bottom Floating Menu Dock
            Positioned(
              bottom: 30,
              left: 24,
              right: 24,
              child: _FloatingDock(onProfileTap: _showProfileMenu),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaggeredBentoGrid() {
    final tiles = [
      _BentoData(
        title: 'Chores',
        subtitle: '3 pending',
        icon: Icons.checklist_rounded,
        color: AppColors.bentoMint,
        crossAxisCellCount: 2,
        mainAxisCellCount: 2,
      ),
      _BentoData(
        title: 'Pantry',
        subtitle: 'Running low!',
        icon: Icons.shopping_basket_rounded,
        color: AppColors.bentoSalmon,
        crossAxisCellCount: 2,
        mainAxisCellCount: 1,
      ),
      _BentoData(
        title: 'Bills',
        subtitle: 'Due in 2d',
        icon: Icons.payments_rounded,
        color: AppColors.bentoLilac,
        crossAxisCellCount: 1,
        mainAxisCellCount: 2,
      ),
      _BentoData(
        title: 'Mood',
        subtitle: 'Vibin\'',
        icon: Icons.emoji_emotions_rounded,
        color: AppColors.bentoLemon,
        crossAxisCellCount: 1,
        mainAxisCellCount: 1,
      ),
    ];

    return StaggeredGrid.count(
      crossAxisCount: 4,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: tiles.asMap().entries.map((entry) {
        final index = entry.key;
        final data = entry.value;
        return StaggeredGridTile.count(
          crossAxisCellCount: data.crossAxisCellCount,
          mainAxisCellCount: data.mainAxisCellCount,
          child: NeoBentoCard(
            color: data.color,
            delay: (index * 100).ms,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${data.title} coming soon ✨'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(data.icon, size: 32, color: data.color.withValues(alpha: 0.8)),
                const SizedBox(height: 12),
                FittedBox(child: Text(data.title, style: Theme.of(context).textTheme.titleLarge)),
                Text(data.subtitle, style: Theme.of(context).textTheme.labelMedium),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _BentoData {
  final String title, subtitle;
  final IconData icon;
  final Color color;
  final int crossAxisCellCount, mainAxisCellCount;

  _BentoData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.crossAxisCellCount,
    required this.mainAxisCellCount,
  });
}

class _FloatingDock extends StatelessWidget {
  const _FloatingDock({required this.onProfileTap});
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _DockIcon(icon: Icons.home_filled, isSelected: true, onTap: () {}),
              _DockIcon(icon: Icons.checklist_rounded, onTap: () {}),
              _DockIcon(icon: Icons.cookie_rounded, onTap: () {}),
              _DockIcon(icon: Icons.person_rounded, onTap: onProfileTap),
            ],
          ),
        ),
      ),
    ).animate().slideY(begin: 1, end: 0, duration: 800.ms, curve: Curves.easeOutBack);
  }
}

class _DockIcon extends StatelessWidget {
  const _DockIcon({required this.icon, this.isSelected = false, required this.onTap});
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      icon: Icon(
        icon,
        color: isSelected ? AppColors.primary : Theme.of(context).textTheme.bodySmall?.color,
        size: 28,
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.icon, required this.label, required this.onTap, this.isDestructive = false});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.accentRed : Theme.of(context).textTheme.bodyLarge?.color;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: color, fontWeight: FontWeight.w800)),
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
