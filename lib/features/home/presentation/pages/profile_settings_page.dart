import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/neo_bento_widgets.dart';
import '../../../auth/presentation/pages/sign_up_page.dart';

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  final _usernameController = TextEditingController();
  final user = Supabase.instance.client.auth.currentUser;
  bool _isLoading = false;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (user == null) return;
    final data = await Supabase.instance.client.from('profiles').select().eq('id', user!.id).single();
    setState(() {
      _usernameController.text = data['username'] ?? '';
      _avatarUrl = data['avatar_url'];
    });
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.from('profiles').update({
        'username': _usernameController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user!.id);
      
      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Profile updated ✨'), behavior: SnackBarBehavior.floating),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.accentRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: Text('Delete Account?', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.accentRed)),
        content: const Text('This action is permanent. All your shared home data will be lost forever.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.accentRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      setState(() => _isLoading = true);
      try {
        final userId = user?.id;
        if (userId != null) {
          // Delete their apartment if they are the last one.
          final profile = await Supabase.instance.client.from('profiles').select('apartment_id').eq('id', userId).maybeSingle();
          if (profile != null && profile['apartment_id'] != null) {
            final aptId = profile['apartment_id'];
            await Supabase.instance.client.from('profiles').update({'apartment_id': null}).eq('id', userId);
            final remaining = await Supabase.instance.client.from('profiles').select('id').eq('apartment_id', aptId);
            if (remaining.isEmpty) {
              await Supabase.instance.client.from('apartments').delete().eq('id', aptId);
            }
          }
          
          // Delete user details from public profiles table
          await Supabase.instance.client.from('profiles').delete().eq('id', userId);

          // Attempt to delete OAuth / Auth record via RPC if available
          try {
            await Supabase.instance.client.rpc('delete_user');
          } catch (rpcError) {
             debugPrint("RPC delete_user failed or not found, OAuth might remain active: $rpcError");
          }
        }
        
        await Supabase.instance.client.auth.signOut();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const SignUpPage()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: NeoBentoBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios_new_rounded)),
                    Text('Profile Settings', style: theme.textTheme.titleLarge),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildAvatarSection(),
                      const SizedBox(height: 40),
                      SquishyCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Display Name', style: theme.textTheme.labelLarge),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _usernameController,
                              decoration: const InputDecoration(hintText: 'Enter username'),
                            ),
                            const SizedBox(height: 32),
                            if (_isLoading)
                              const Center(child: CircularProgressIndicator())
                            else
                              SquishyButton(label: 'Save Changes', onPressed: _updateProfile),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      _buildDangerZone(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.primary, width: 3)),
              child: CircleAvatar(
                radius: 60,
                backgroundImage: NetworkImage(_avatarUrl ?? 'https://api.dicebear.com/7.x/avataaars/svg?seed=${user?.id}'),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: () {
                  // Trigger PFP update logic
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 16),
        Text('Change Profile Picture', style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }

  Widget _buildDangerZone() {
    return SquishyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Danger Zone', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.accentRed)),
          const SizedBox(height: 16),
          Text('Once you delete your account, there is no going back. Please be certain.', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),
          SquishyButton(
            label: 'Delete Account',
            onPressed: _confirmDelete,
            isPrimary: false,
          ),
        ],
      ),
    );
  }
}