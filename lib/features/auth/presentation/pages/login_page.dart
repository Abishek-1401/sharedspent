import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/widgets/neo_bento_widgets.dart';
import 'sign_up_page.dart';
import 'forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // --- SIGN IN WITH EMAIL ---
  Future<void> _signIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar('Please fill in all fields', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // AuthGate will automatically redirect to HomePage on success
    } on AuthException catch (error) {
      _showSnackBar(error.message, isError: true);
    } catch (error) {
      _showSnackBar('An unexpected error occurred');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- SIGN IN WITH GOOGLE ---
  Future<void> _signInWithGoogle() async {
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        // This matches the deep link we added to the Android Manifest
        redirectTo: 'io.supabase.cohabit://login-callback', 
      );
    } on AuthException catch (error) {
      _showSnackBar(error.message, isError: true);
    } catch (error) {
      _showSnackBar('Google Sign-In failed');
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

  Route<T> _bentoRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.elasticOut,
          reverseCurve: Curves.easeOut,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
      transitionDuration: 650.ms,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: NeoBentoBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // TOP: Header
                Column(
                  children: [
                    const SizedBox(height: 40),
                    Hero(
                      tag: 'logo_text',
                      child: FittedBox(
                        child: Text(
                          'Cohabit',
                          style: theme.textTheme.displayLarge,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),
                    const SizedBox(height: 12),
                    Text(
                      'Sign in to your shared home',
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 200.ms),
                  ],
                ),

                // MIDDLE: Card
                SquishyCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Welcome back, roomie 👋',
                        style: theme.textTheme.titleLarge,
                      ).animate().fadeIn(duration: 400.ms),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email address',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ).animate().fadeIn(delay: 150.ms),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                      ).animate().fadeIn(delay: 250.ms),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).push(_bentoRoute(const ForgotPasswordPage()));
                          },
                          child: Text(
                            "Forgot password?",
                            style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ).animate().fadeIn(delay: 300.ms),
                      const SizedBox(height: 12),
                      if (_isLoading)
                        const Center(child: CircularProgressIndicator())
                      else
                        SquishyButton(
                          label: 'Sign in',
                          onPressed: _signIn,
                          isPrimary: true,
                        ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0),
                            child: Text('or', style: theme.textTheme.labelMedium),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SquishyButton(
                        label: 'Continue with Google',
                        isPrimary: false,
                        onPressed: _signInWithGoogle,
                        leading: const FaIcon(FontAwesomeIcons.google, size: 18, color: Colors.redAccent),
                      ),
                    ],
                  ),
                ),

                // BOTTOM: Footer Link
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: TextButton(
                    onPressed: () => Navigator.of(context).push(_bentoRoute(const SignUpPage())),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        text: "New to Cohabit? ",
                        style: theme.textTheme.bodyMedium,
                        children: [
                          TextSpan(
                            text: 'Create an account',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 500.ms),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}