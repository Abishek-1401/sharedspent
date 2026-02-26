import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/widgets/neo_bento_widgets.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isSent = false;

  Future<void> _sendMagicLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your email address')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      // "Magic Link" - Sends a login link to their email
      // Note: This requires the user to click the link on the same device 
      // or standard Password Reset if you prefer that flow.
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.cohabit://login-callback', // Standard deep link format
      );
      
      setState(() => _isSent = true);
    } on AuthException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message), backgroundColor: Theme.of(context).colorScheme.error));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unexpected error occurred')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: NeoBentoBackground(
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: theme.colorScheme.primary,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'Reset password',
                style: theme.textTheme.titleLarge,
              ),
              centerTitle: true,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: _isSent ? _buildSuccessView(theme) : _buildFormView(theme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // View 1: The Form
  Widget _buildFormView(ThemeData theme) {
    final muted = theme.brightness == Brightness.dark
        ? theme.colorScheme.onSurface.withValues(alpha: 0.75)
        : Colors.grey.shade700;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Forgot Password?", style: theme.textTheme.displayMedium)
            .animate().fadeIn().slideX(begin: -0.2, end: 0),
        const SizedBox(height: 10),
        Text(
          "Don't worry! It happens. Please enter the address associated with your account.",
          style: theme.textTheme.bodyMedium?.copyWith(color: muted),
        ).animate().fadeIn(delay: 200.ms),
        
        const SizedBox(height: 40),
        
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email ID',
            prefixIcon: Icon(Icons.alternate_email),
          ),
        ).animate().fadeIn(delay: 300.ms),
        
        const SizedBox(height: 30),
        
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else
          ElevatedButton(
            onPressed: _sendMagicLink,
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
            child: const Text("Send Magic Link"),
          )
              .animate()
              .fadeIn(delay: 400.ms)
              .scale(duration: 550.ms, curve: Curves.elasticOut),
      ],
    );
  }

  // View 2: Success Message (Cute/Friendly)
  Widget _buildSuccessView(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 140,
          child: (Lottie.network(
            'https://assets10.lottiefiles.com/packages/lf20_q5pk6p1k.json',
            repeat: false,
            fit: BoxFit.contain,
          ) as Widget)
              .animate()
              .fadeIn(duration: 600.ms)
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1, 1),
                curve: Curves.elasticOut,
              ),
        ),
        const SizedBox(height: 20),
        Text("Check your mail!", style: theme.textTheme.displayMedium, textAlign: TextAlign.center),
        const SizedBox(height: 10),
        Text(
          "We have sent a password recover instructions to your email.",
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Back to Login"),
        ),
      ],
    );
  }
}