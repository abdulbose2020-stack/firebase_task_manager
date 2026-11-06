import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends State<EmailVerificationScreen> {
  final AuthService _authService = AuthService();
  bool _isChecking = false;
  bool _isResending = false;

  String get _email =>
      FirebaseAuth.instance.currentUser?.email ?? '';

  Future<void> _checkVerification() async {
    setState(() => _isChecking = true);

    try {
      await FirebaseAuth.instance.currentUser?.reload();

      final isVerified =
          FirebaseAuth.instance.currentUser?.emailVerified ?? false;

      if (!mounted) return;

      if (isVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email verified successfully!'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your email is not verified yet.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not check verification status.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  Future<void> _resendVerification() async {
    setState(() => _isResending = true);

    try {
      await _authService.sendEmailVerification();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification email sent successfully.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not send verification email.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  Future<void> _signOut() async {
    await _authService.logout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.mark_email_unread_outlined,
                  size: 90,
                  color: Color(0xFF172B4D),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Verify your email',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF172B4D),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'We have sent a verification link to:',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _email,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF172B4D),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Please check your inbox and click the '
                  'verification link before accessing TaskFlow.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        _isResending ? null : _resendVerification,
                    child: _isResending
                        ? const CircularProgressIndicator()
                        : const Text('Resend verification email'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed:
                        _isChecking ? null : _checkVerification,
                    child: _isChecking
                        ? const CircularProgressIndicator()
                        : const Text("I've verified my email"),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: _signOut,
                  child: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
