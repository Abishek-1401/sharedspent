import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/constants/avatar_presets.dart';
import '../../../../core/widgets/neo_bento_widgets.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _usernameController = TextEditingController();
  String? _selectedAvatarUrl = AvatarPresets.list.first; // Default choice
  File? _customImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  // --- PICK CUSTOM IMAGE ---
  Future<void> _pickCustomImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source, imageQuality: 50);
    if (image != null) {
      setState(() {
        _customImage = File(image.path);
        _selectedAvatarUrl = null; // Deselect presets if custom is picked
      });
    }
  }

  // --- SAVE PROFILE & REDIRECT ---
  Future<void> _saveProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || _usernameController.text.trim().isEmpty) {
      _showError('Please enter a username');
      return;
    }

    // SNAPPY UI: Hide keyboard immediately so the transition feels smooth
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);
    try {
      String finalAvatarUrl = _selectedAvatarUrl ?? '';

      // 1. Upload if custom image exists
      if (_customImage != null) {
        final path = 'public/${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await Supabase.instance.client.storage.from('avatars').upload(path, _customImage!);
        finalAvatarUrl = Supabase.instance.client.storage.from('avatars').getPublicUrl(path);
      }

      // 2. Update the profiles table
      // The AuthGate's StreamBuilder will see this change and swap the page automatically
      await Supabase.instance.client.from('profiles').update({
        'username': _usernameController.text.trim(),
        'avatar_url': finalAvatarUrl,
      }).eq('id', user.id);

    } catch (e) {
      _showError(e.toString());
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Theme.of(context).colorScheme.error),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: NeoBentoBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                            ),
                            child: Text(
                              'Step 2 of 2',
                              style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        FittedBox(
                          child: Text(
                            "Set up your vibe",
                            style: theme.textTheme.displayMedium,
                          ),
                        ).animate().fadeIn().slideX(begin: -0.2, end: 0),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 40),
                Expanded(
                  child: SquishyCard(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Choose your avatar",
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Pick one that represents you best!",
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 32),
                          Center(
                            child: Hero(
                              tag: 'avatar_selection',
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: theme.colorScheme.primary,
                                    width: 3,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 60,
                                  backgroundImage: NetworkImage(_selectedAvatarUrl ?? ''),
                                ),
                              ),
                            ),
                          ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                          const SizedBox(height: 40),
                          _buildAvatarPinboard(theme),
                          const SizedBox(height: 40),
                          Text(
                            "What should we call you?",
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _usernameController,
                            decoration: const InputDecoration(
                              labelText: 'Username',
                              prefixIcon: Icon(Icons.face_rounded),
                              hintText: 'e.g. SuperRoomie',
                            ),
                          ),
                          const SizedBox(height: 40),
                          if (_isLoading)
                            const Center(child: CircularProgressIndicator())
                          else
                            SquishyButton(
                              label: 'Start Cohabiting',
                              onPressed: _saveProfile,
                            ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- CUSTOM PINBOARD WIDGET ---
  Widget _buildAvatarPinboard(ThemeData theme) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        // Developer Presets (Pinboard Style)
        ...AvatarPresets.list.map((url) {
          final isSelected = _selectedAvatarUrl == url;
          return GestureDetector(
            onTap: () => setState(() { 
              _selectedAvatarUrl = url; 
              _customImage = null; 
            }),
            child: AnimatedContainer(
              duration: 200.ms,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? theme.primaryColor : Colors.transparent, 
                  width: 3,
                ),
              ),
              child: CircleAvatar(
                radius: 35, 
                backgroundColor: theme.colorScheme.surface,
                backgroundImage: NetworkImage(url),
              ),
            ),
          );
        }),
        
        // Custom Upload Button (Gallery)
        GestureDetector(
          onTap: () => _pickCustomImage(ImageSource.gallery),
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: _customImage != null ? theme.primaryColor : theme.dividerColor, 
                width: 2,
              ),
            ),
            child: _customImage != null 
                ? ClipOval(child: Image.file(_customImage!, fit: BoxFit.cover))
                : const Icon(Icons.add_a_photo_outlined),
          ),
        ),
      ],
    );
  }
}