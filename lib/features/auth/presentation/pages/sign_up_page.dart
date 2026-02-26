import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Join Cohabit.', style: theme.textTheme.displayLarge)
                  .animate().fadeIn().slideY(begin: 0.1, end: 0),
              
              const SizedBox(height: 8),
              
              Text('Start managing your shared home together.', style: theme.textTheme.bodyMedium)
                  .animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 40),

              OutlinedButton.icon(
                onPressed: _signUpWithGoogle,
                icon: const FaIcon(FontAwesomeIcons.google, size: 18),
                label: const Text('Sign Up with Google'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 24),

              Row(children: [
                Expanded(child: Divider(color: theme.dividerColor)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('OR', style: theme.textTheme.labelMedium),
                ),
                Expanded(child: Divider(color: theme.dividerColor)),
              ]),

              const SizedBox(height: 24),

              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email_outlined)),
              ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 16),

              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
              ).animate().fadeIn(delay: 500.ms),

              const SizedBox(height: 32),

              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _signUp,
                  child: const Text('Create Account'),
                ).animate().fadeIn(delay: 600.ms).scale(),
                
              const SizedBox(height: 24),

              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Already have an account? Sign In", 
                    style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}