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
import '../../../inventory/presentation/pages/grocery_page.dart';
import '../../../bills/presentation/pages/bill_page.dart';
import 'room_setup_page.dart';
import '../../../inventory/presentation/pages/shopping_list_page.dart';
import '../../../bills/presentation/pages/spinner_page.dart';
import 'package:google_fonts/google_fonts.dart';

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
          if (_apartmentData != null)
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
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: QrImageView(
              data: inviteCode,
              version: QrVersions.auto,
              size: 150.0,
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
          const SizedBox(height: 16),
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

  void _showRoomMenu() {
    HapticFeedback.mediumImpact();
    final apartmentName = _apartmentData?['name'] ?? 'Your Home';
    final inviteCode = _apartmentData?['invite_code'] ?? '------';
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (modalContext) => GlassSheet(
        title: 'Room Settings',
        children: [
          ListTile(
            leading: const Icon(Icons.meeting_room_rounded),
            title: Text(apartmentName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Tap to edit name'),
            trailing: const Icon(Icons.edit_rounded, size: 20),
            onTap: () {
              Navigator.pop(modalContext);
              _showEditRoomNameDialog(apartmentName);
            },
          ),
          ListTile(
            leading: const Icon(Icons.qr_code_rounded),
            title: Text('Invite Code: $inviteCode', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Tap to share QR'),
            trailing: const Icon(Icons.share_rounded, size: 20),
            onTap: () {
              Navigator.pop(modalContext);
              _showShareInvite();
            },
          ),
          const Divider(height: 32, thickness: 1),
          Text('Roommates (${_roommates.length})', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 250),
            child: SingleChildScrollView(
              child: Column(
                children: _roommates.map((r) {
                  return ListTile(
                    leading: CircleAvatar(backgroundImage: NetworkImage(r['avatar_url'] ?? 'https://api.dicebear.com/7.x/avataaars/svg?seed=${r['id']}')),
                    title: Text(r['username'] ?? 'Roomie', style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: r['id'] == user?.id ? const Text('You') : const Text('Member'),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(height: 32, thickness: 1),
          _MenuTile(
            icon: Icons.exit_to_app_rounded,
            label: 'Leave Room',
            isDestructive: true,
            onTap: () {
              Navigator.pop(modalContext);
              _leaveRoom();
            },
          )
        ],
      ),
    );
  }

  void _showEditRoomNameDialog(String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Room Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'New Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && _apartmentData != null) {
                Navigator.pop(dialogContext);
                try {
                  await Supabase.instance.client.from('apartments').update({'name': newName}).eq('id', _apartmentData!['id']);
                  _fetchProfile(); // Refresh UI
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _leaveRoom() async {
    bool isLastRoommate = false;
    final apartmentId = _apartmentData?['id'];
    
    if (apartmentId != null) {
      try {
        final remaining = await Supabase.instance.client.from('profiles').select('id').eq('apartment_id', apartmentId);
        if (remaining.length <= 1) {
          isLastRoommate = true;
        }
      } catch (_) {}
    }

    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isLastRoommate ? 'Delete Room?' : 'Leave Room?'),
        content: Text(isLastRoommate 
            ? 'You are the last member here. Do you want to leave and delete the room permanently? All bills and groceries will be wiped.'
            : 'Are you sure you want to leave this shared home? You will need an invite code to rejoin.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(isLastRoommate ? 'Delete Room' : 'Leave', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      try {
        await Supabase.instance.client.from('profiles').update({'apartment_id': null}).eq('id', user!.id);
        
        if (isLastRoommate && apartmentId != null) {
          try {
             // Fetch all bills to delete splits and items manually for cascade
             final bills = await Supabase.instance.client.from('bills').select('id').eq('apartment_id', apartmentId);
             for (var b in bills) {
                await Supabase.instance.client.from('bill_splits').delete().eq('bill_id', b['id']);
                await Supabase.instance.client.from('bill_items').delete().eq('bill_id', b['id']);
             }
             await Supabase.instance.client.from('bills').delete().eq('apartment_id', apartmentId);
             await Supabase.instance.client.from('inventory').delete().eq('apartment_id', apartmentId);
             await Supabase.instance.client.from('apartments').delete().eq('id', apartmentId);
          } catch (e) {
             debugPrint('Force cascade delete failed: $e');
          }
        }

        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RoomSetupPage()));
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error leaving room: $e")));
      }
    }
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
                onGroceryTap: () {
                  if (_apartmentData == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Join or create a room first! ✨'), behavior: SnackBarBehavior.floating));
                  } else {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const GroceryPage()));
                  }
                },
                onBillTap: () {
                  if (_apartmentData == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Join or create a room first! ✨'), behavior: SnackBarBehavior.floating));
                  } else {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const BillPage()));
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaggeredBentoGrid() {
    final apartment = _profileData?['apartments'];
    final bool hasRoom = apartment != null;

    final tiles = [
      _BentoData(
        title: hasRoom ? (apartment['name'] ?? 'Your Room') : 'Join a Room',
        subtitle: hasRoom ? '${_roommates.length} Roommates' : 'Tap to initialize',
        icon: Icons.home_rounded,
        color: AppColors.accentMint,
        crossAxisCellCount: 2,
        mainAxisCellCount: 3,
      ),
      _BentoData(
        title: 'Inventory',
        subtitle: hasRoom ? 'Milk run out' : 'Not available',
        icon: Icons.shopping_basket_rounded,
        color: hasRoom ? AppColors.accentPink : Colors.grey.withValues(alpha: 0.3),
        crossAxisCellCount: 2,
        mainAxisCellCount: 2,
      ),
      _BentoData(
        title: 'Expenses',
        subtitle: hasRoom ? 'Due in 2d' : 'Not available',
        icon: Icons.payments_rounded,
        color: hasRoom ? AppColors.accentBlue : Colors.grey.withValues(alpha: 0.3),
        crossAxisCellCount: 2,
        mainAxisCellCount: 3,
      ),
      _BentoData(
        title: 'Shopping List',
        subtitle: hasRoom ? 'Manage items' : 'Not available',
        icon: Icons.format_list_bulleted_rounded,
        color: hasRoom ? AppColors.accentYellow : Colors.grey.withValues(alpha: 0.3),
        crossAxisCellCount: 2,
        mainAxisCellCount: 2,
      ),
      _BentoData(
        title: 'Spin to Pay',
        subtitle: hasRoom ? 'Settle disputes!' : 'Not available',
        icon: Icons.casino_rounded,
        color: hasRoom ? AppColors.accentPink : Colors.grey.withValues(alpha: 0.3),
        crossAxisCellCount: 2,
        mainAxisCellCount: 2,
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
            padding: const EdgeInsets.all(16),
            delay: (index * 100).ms,
            onTap: () {
              if (index == 0) {
                if (!hasRoom) {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RoomSetupPage()));
                } else {
                  _showRoomMenu();
                }
              } else if (!hasRoom) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Join or create a room first! ✨'), behavior: SnackBarBehavior.floating));
              } else if (data.title == 'Inventory') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const GroceryPage()));
              } else if (data.title == 'Expenses') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const BillPage()));
              } else if (data.title == 'Shopping List') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ShoppingListPage()));
              } else if (data.title == 'Spin to Pay') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => SpinnerPage(roommates: _roommates)));
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
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(data.icon, size: 36, color: Theme.of(context).colorScheme.onSurface),
                  const SizedBox(height: 14),
                  Text(data.title, style: GoogleFonts.bricolageGrotesque(fontWeight: FontWeight.bold, fontSize: 22, color: Theme.of(context).colorScheme.onSurface)),
                  const SizedBox(height: 4),
                  Text(data.subtitle, style: GoogleFonts.outfit(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
                ],
              ),
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
