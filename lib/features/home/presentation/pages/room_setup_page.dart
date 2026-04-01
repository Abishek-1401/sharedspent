import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:math';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/neo_bento_widgets.dart';
import 'home_page.dart';

class RoomSetupPage extends StatefulWidget {
  const RoomSetupPage({super.key});

  @override
  State<RoomSetupPage> createState() => _RoomSetupPageState();
}

class _RoomSetupPageState extends State<RoomSetupPage> {
  final _roomNameController = TextEditingController();
  final _roomIdController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _roomNameController.dispose();
    _roomIdController.dispose();
    super.dispose();
  }

  // --- LOGIC: CREATE ROOM ---
  Future<void> _createRoom() async {
    if (_isLoading) return; // 🛡️ Guard against double clicks
    
    final name = _roomNameController.text.trim();
    if (name.isEmpty) {
      _showSnackBar("Please give your shared home a name!");
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        _showSnackBar("Session expired. Please sign in again.");
        return;
      }

      // 1. Generate unique 6-digit Room ID
      final roomId = _generateRoomId();

      // 2. Insert into apartments table
      final roomResponse = await Supabase.instance.client.from('apartments').insert({
        'name': name,
        'invite_code': roomId,
      }).select().single();

      final apartmentId = roomResponse['id'];

      // 3. Link user to apartment
      await Supabase.instance.client.from('profiles').update({
        'apartment_id': apartmentId,
      }).eq('id', user.id);

      // Successfully linked!
      if (mounted) {
        _showSnackBar("Room created successfully! Welcome home. ✨");
        // Force navigation to clear the state and ensure user lands on HomePage
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomePage()),
          (route) => false,
        );
      }

    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar("Error creating room: $e");
      }
    }
  }

  // --- LOGIC: JOIN ROOM ---
  Future<void> _joinRoom(String code) async {
    if (_isLoading) return; // 🛡️ Guard against double clicks
    
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.length != 6) {
      _showSnackBar("Please enter a valid 6-digit code.");
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        _showSnackBar("Session expired. Please sign in again.");
        return;
      }

      // 1. Find room by invite_code
      final roomResponse = await Supabase.instance.client
          .from('apartments')
          .select()
          .eq('invite_code', cleanCode)
          .maybeSingle();

      if (roomResponse == null) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showSnackBar("Room not found. Check the code and try again.");
        }
        return;
      }

      final apartmentId = roomResponse['id'];

      // 2. Link user to apartment
      await Supabase.instance.client.from('profiles').update({
        'apartment_id': apartmentId,
      }).eq('id', user.id);

      if (mounted) {
        _showSnackBar("Joined successfully! Welcome to the space. 🏠");
        // Force navigation to clear the state and ensure user lands on HomePage
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomePage()),
          (route) => false,
        );
      }

    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar("Error joining room: $e");
      }
    }
  }

  String _generateRoomId() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Exclude ambiguous chars
    return List.generate(6, (index) => chars[Random().nextInt(chars.length)]).join();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  // --- UI: RENDER ---
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: NeoBentoBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage())),
                    child: const Text('Skip for now', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),
                FittedBox(
                  child: Text(
                    "Welcome to your\nnew life",
                    style: theme.textTheme.displayLarge,
                    textAlign: TextAlign.center,
                  ),
                ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),
                const SizedBox(height: 12),
                Text(
                  "Cohabit works better together.\nCreate a space or join your roomies.",
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 40),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Path 1: Create
                        SquishyCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Create a Room", style: theme.textTheme.titleLarge),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _roomNameController,
                                decoration: const InputDecoration(
                                  labelText: "Apartment Name",
                                  hintText: "e.g. The Breakfast Club",
                                ),
                              ),
                              const SizedBox(height: 24),
                              _isLoading 
                                ? const Center(child: CircularProgressIndicator())
                                : SquishyButton(
                                    label: "Initialize Space",
                                    onPressed: _createRoom,
                                  ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1, end: 0),

                        const SizedBox(height: 24),

                        // Path 2: Join
                        SquishyCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Join a Room", style: theme.textTheme.titleLarge),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _roomIdController,
                                decoration: const InputDecoration(
                                  labelText: "6-Digit Code",
                                  hintText: "e.g. AB1234",
                                ),
                                textCapitalization: TextCapitalization.characters,
                              ),
                              const SizedBox(height: 24),
                              _isLoading 
                                ? const Center(child: CircularProgressIndicator())
                                : Row(
                                    children: [
                                      Expanded(
                                        child: SquishyButton(
                                          label: "Join with ID",
                                          onPressed: () => _joinRoom(_roomIdController.text),
                                          isPrimary: false,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      IconButton(
                                        onPressed: _openQrScanner,
                                        icon: const Icon(Icons.qr_code_scanner_rounded),
                                        style: IconButton.styleFrom(
                                          backgroundColor: AppColors.primarySoft,
                                          padding: const EdgeInsets.all(16),
                                        ),
                                      ),
                                    ],
                                  ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 600.ms).slideX(begin: 0.1, end: 0),
                      ],
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

  void _openQrScanner() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassSheet(
        title: "Scan Roomie QR",
        children: [
          SizedBox(
            height: 300,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: MobileScanner(
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  if (barcodes.isNotEmpty) {
                    final String? code = barcodes.first.rawValue;
                    if (code != null) {
                      Navigator.pop(context);
                      _joinRoom(code);
                    }
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text("Position the QR code inside the frame", textAlign: TextAlign.center),
        ],
      ),
    );
  }
}