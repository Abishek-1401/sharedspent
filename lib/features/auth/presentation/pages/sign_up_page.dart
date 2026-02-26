import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/widgets/neo_bento_widgets.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signUp() async {
    if (_emailController.text.isEmpty || _passwordController.text.length < 6) {
      _showSnackBar('Please enter valid credentials (min 6 chars)', isError: true);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) _showSnackBar('Account created! Checking verification...');
    } on AuthException catch (error) {
      _showSnackBar(error.message, isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signUpWithGoogle() async {
    FocusScope.of(context).unfocus();
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.cohabit://login-callback',
      );
    } catch (error) {
      _showSnackBar('Google Sign Up failed', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: NeoBentoBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    ),
                    const Spacer(),
                    Chip(
                      label: Text(
                        'Step 1 of 2',
                        style: theme.textTheme.labelMedium,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Text(
                  'Create your cozy hub',
                  style: theme.textTheme.displayMedium,
                ).animate().fadeIn().slideY(begin: 0.1, end: 0),

                const SizedBox(height: 6),

                Text(
                  'We’ll set up your account so you can invite housemates next.',
                  style: theme.textTheme.bodyMedium,
                ).animate().fadeIn(delay: 160.ms),

                const SizedBox(height: 24),

                SquishyCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SquishyButton(
                        label: 'Continue with Google',
                        isPrimary: false,
                        onPressed: _signUpWithGoogle,
                        leading: const FaIcon(
                          FontAwesomeIcons.google,
                          size: 18,
                          color: Colors.redAccent,
                        ),
                      ).animate().fadeIn(delay: 120.ms),

                      const SizedBox(height: 18),

                      Row(
                        children: [
                          Expanded(child: Divider(color: theme.dividerColor)),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12.0),
                            child: Text(
                              'or use email',
                              style: theme.textTheme.labelMedium,
                            ),
                          ),
                          Expanded(child: Divider(color: theme.dividerColor)),
                        ],
                      ),

                      const SizedBox(height: 18),

                      TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email address',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ).animate().fadeIn(delay: 220.ms),

                      const SizedBox(height: 12),

                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Create a password',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                      ).animate().fadeIn(delay: 320.ms),

                      const SizedBox(height: 20),

                      if (_isLoading)
                        const Center(child: CircularProgressIndicator())
                      else
                        SquishyButton(
                          label: 'Create account',
                          onPressed: _signUp,
                          isPrimary: true,
                        )
                            .animate()
                            .fadeIn(delay: 400.ms)
                            .scale(duration: 550.ms, curve: Curves.elasticOut),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "Already have an account? Sign in",
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
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
}