import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/neo_bento_widgets.dart';
import '../../../../main.dart';
import 'profile_settings_page.dart';
import 'grocery_page.dart';
import 'bill_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final user = Supabase.instance.client.auth.currentUser;
  Map<String, dynamic>? _profileData;
  Map<String, dynamic>? _apartmentData;
  List<Map<String, dynamic>> _roommates = [];

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    _fetchRoommates();
  }

  Future<void> _fetchProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('*, apartments(*)')
          .eq('id', user.id)
          .maybeSingle();

      if (mounted && response != null) {
        setState(() {
          _profileData = response;
          _apartmentData = response['apartments'];
        });
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    }
  }

  Future<void> _fetchRoommates() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final profile = await Supabase.instance.client.from('profiles').select('apartment_id').eq('id', user.id).maybeSingle();
      if (profile != null && profile['apartment_id'] != null) {
        final apartmentId = profile['apartment_id'];
        final response = await Supabase.instance.client.from('profiles').select().eq('apartment_id', apartmentId);
        if (mounted) {
          setState(() {
            _roommates = List<Map<String, dynamic>>.from(response);
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _roommates = [];
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching roommates: $e");
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
            icon: Icons.share_rounded,
            label: 'Share Invite',
            onTap: () {
              Navigator.pop(context);
              _showShareInvite();
            },
          ),
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

  void _showShareInvite() {
    final inviteCode = _apartmentData?['invite_code'] ?? '------';
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassSheet(
        title: 'Invite Roommates',
        children: [
          const Text(
            "Share this code or scan the QR to join this home.",
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: QrImageView(
              data: inviteCode,
              version: QrVersions.auto,
              size: 200.0,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.circle,
                color: Colors.black,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.circle,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              inviteCode,
              style: theme.textTheme.displaySmall?.copyWith(
                letterSpacing: 8,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          SquishyButton(
            label: 'Copy Invite Link',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: "Join my Cohabit room! Code: $inviteCode"));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Invite copied to clipboard! ✨")),
              );
              Navigator.pop(context);
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
    final apartmentName = _apartmentData?['name'] ?? 'Your Home';

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
                            apartmentName,
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
                        const SizedBox(height: 16),
                        
                        // Roommates Row
                        if (_roommates.isNotEmpty)
                          SizedBox(
                            height: 40,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _roommates.length,
                              itemBuilder: (context, index) {
                                final roommate = _roommates[index];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Tooltip(
                                    message: roommate['username'] ?? 'Roomie',
                                    child: CircleAvatar(
                                      radius: 16,
                                      backgroundImage: NetworkImage(roommate['avatar_url'] ?? ''),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ).animate().fadeIn(delay: 300.ms),

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
              child: _FloatingDock(
                onProfileTap: _showProfileMenu,
                onGroceryTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GroceryPage())),
                onBillTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BillPage())),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaggeredBentoGrid() {
    final apartment = _profileData?['apartments'];
    final tiles = [
      _BentoData(
        title: apartment?['name'] ?? 'Your Room',
        subtitle: '${_roommates.length} Roommates',
        icon: Icons.home_rounded,
        color: AppColors.bentoMint,
        crossAxisCellCount: 2,
        mainAxisCellCount: 2,
      ),
      _BentoData(
        title: 'Inventory',
        subtitle: 'Milk run out',
        icon: Icons.shopping_basket_rounded,
        color: AppColors.bentoSalmon,
        crossAxisCellCount: 2,
        mainAxisCellCount: 1,
      ),
      _BentoData(
        title: 'Expenses',
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
              if (data.title == 'Inventory') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const GroceryPage()));
              } else if (data.title == 'Expenses') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const BillPage()));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${data.title} coming soon ✨'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                );
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(data.icon, size: 32, color: Colors.black87),
                const SizedBox(height: 12),
                FittedBox(child: Text(data.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
                Text(data.subtitle, style: const TextStyle(fontSize: 14, color: Colors.black54)),
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
  const _FloatingDock({
    required this.onProfileTap,
    required this.onGroceryTap,
    required this.onBillTap,
  });
  final VoidCallback onProfileTap;
  final VoidCallback onGroceryTap;
  final VoidCallback onBillTap;

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
              _DockIcon(icon: Icons.shopping_basket_rounded, onTap: onGroceryTap),
              _DockIcon(icon: Icons.payments_rounded, onTap: onBillTap),
              _DockIcon(icon: Icons.analytics_rounded, onTap: () {}),
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
