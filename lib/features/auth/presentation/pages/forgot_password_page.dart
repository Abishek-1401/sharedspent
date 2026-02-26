import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _isSent ? _buildSuccessView(theme) : _buildFormView(theme),
        ),
      ),
    );
  }

  // View 1: The Form
  Widget _buildFormView(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Forgot Password?", style: theme.textTheme.displayMedium)
            .animate().fadeIn().slideX(begin: -0.2, end: 0),
        const SizedBox(height: 10),
        Text(
          "Don't worry! It happens. Please enter the address associated with your account.",
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
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
          ).animate().fadeIn(delay: 400.ms).scale(),
      ],
    );
  }

  // View 2: Success Message (Cute/Friendly)
  Widget _buildSuccessView(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.mark_email_read_outlined, size: 80, color: Colors.green)
            .animate().scale(duration: 500.ms, curve: Curves.elasticOut),
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