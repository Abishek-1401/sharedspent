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
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    const BackButton(),
                    const Spacer(),
                    Text(
                      'Reset password',
                      style: theme.textTheme.titleLarge,
                    ),
                    const Spacer(),
                    const SizedBox(width: 48), // Balance
                  ],
                ),
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
      ),
    );
  }

  // View 1: The Form
  Widget _buildFormView(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text("Forgot\nPassword?", style: theme.textTheme.displayMedium),
        ).animate().fadeIn().slideX(begin: -0.2, end: 0),
        const SizedBox(height: 12),
        Text(
          "Don't worry! It happens. Please enter the address associated with your account.",
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
        ).animate().fadeIn(delay: 200.ms),
        
        const SizedBox(height: 40),
        
        SquishyCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email ID',
                  prefixIcon: Icon(Icons.alternate_email),
                ),
              ).animate().fadeIn(delay: 300.ms),
              
              const SizedBox(height: 32),
              
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                SquishyButton(
                  label: "Send Magic Link",
                  onPressed: _sendMagicLink,
                  isPrimary: true,
                ),
            ],
          ),
        ),
      ],
    );
  }

  // View 2: Success Message (Cute/Friendly)
  Widget _buildSuccessView(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 200,
          child: Animate(
            effects: [
              FadeEffect(duration: 600.ms),
              ScaleEffect(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1, 1),
                curve: Curves.elasticOut,
              ),
            ],
            child: Lottie.network(
              'https://assets10.lottiefiles.com/packages/lf20_q5pk6p1k.json',
              repeat: false,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 32),
        FittedBox(child: Text("Check your mail!", style: theme.textTheme.displayMedium, textAlign: TextAlign.center)),
        const SizedBox(height: 16),
        Text(
          "We have sent password recovery instructions to your email.",
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800) ?? 
                 const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 48),
        SquishyButton(
          label: "Back to Login",
          onPressed: () => Navigator.pop(context),
          isPrimary: true,
        ),
      ],
    );
  }
}