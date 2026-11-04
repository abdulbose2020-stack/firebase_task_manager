import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';
import 'package:flutter/services.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;

  static const Color navy = Color(0xFF172B4D);
  static const Color background = Color(0xFFF5F7FB);
  static const Color muted = Color(0xFF8993A4);

  Future<void> _login() async {
    if (_isLoading) return;

    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    final messenger = ScaffoldMessenger.of(context);

    try {
      await _authService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text(_loginErrorMessage(e.code)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _continueAsGuest() async {
    if (_isLoading) return;

    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    final messenger = ScaffoldMessenger.of(context);

    try {
      await _authService.signInAnonymously();
    } catch (_) {
      if (!mounted) return;

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Guest sign-in failed. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty ||
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address first.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);

    try {
      await _authService.resetPassword(email);

      if (!mounted) return;

      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'If the account is eligible, a password reset email will be sent.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            e.code == 'invalid-email'
                ? 'Please enter a valid email address.'
                : 'Could not send the reset email. Please try again.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Check your internet connection and try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openRegisterScreen() {
    if (_isLoading) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  String _loginErrorMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';

      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';

      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';

      case 'network-request-failed':
        return 'Check your internet connection and try again.';

      default:
        return 'Login failed. Please check your details and try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Color(0xFF172B4D),
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: Color(0xFFF5F7FB),
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    children: [
                      _buildHeader(),

                      Transform.translate(
                        offset: const Offset(0, -25),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          child: _buildLoginCard(),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.only(bottom: 24, top: 0),
                        child: Text(
                          'Organize your day. Achieve more.',
                          style: TextStyle(
                            color: muted,
                            fontSize: 12,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        28,
        MediaQuery.of(context).padding.top + 25,
        28,
        65,
      ),
      decoration: const BoxDecoration(
        color: navy,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(35),
          bottomRight: Radius.circular(35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.task_alt_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'TASK MANAGER',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.8,
                ),
              ),
            ],
          ),

          const SizedBox(height: 35),

          const Text(
            'Welcome Back!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            'Your tasks are waiting. Let’s get things done.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 480),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: navy.withValues(alpha: 0.07),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Login to your account',
                style: TextStyle(
                  color: navy,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 7),

              const Text(
                'Enter your details to continue.',
                style: TextStyle(color: muted, fontSize: 13),
              ),

              const SizedBox(height: 28),

              const Text(
                'Email Address',
                style: TextStyle(
                  color: navy,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 9),

              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.username],
                decoration: const InputDecoration(
                  hintText: 'Enter your email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your email.';
                  }

                  if (!RegExp(
                    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                  ).hasMatch(value.trim())) {
                    return 'Please enter a valid email address.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 21),

              const Text(
                'Password',
                style: TextStyle(
                  color: navy,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 9),

              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onFieldSubmitted: (_) {
                  if (!_isLoading) _login();
                },
                decoration: InputDecoration(
                  hintText: 'Enter your password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    tooltip: _obscurePassword
                        ? 'Show password'
                        : 'Hide password',
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 8),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isLoading ? null : _forgotPassword,
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: navy,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: navy,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: navy.withValues(alpha: 0.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 23,
                          width: 23,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Login'),
                            SizedBox(width: 9),
                            Icon(Icons.arrow_forward_rounded, size: 19),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 23),

              Row(
                children: [
                  const Expanded(child: Divider(color: Color(0xFFE5E9F0))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        color: muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: Color(0xFFE5E9F0))),
                ],
              ),

              const SizedBox(height: 17),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _continueAsGuest,
                  icon: const Icon(Icons.person_outline_rounded),
                  label: const Text('Continue as Guest'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: navy,
                    side: const BorderSide(color: Color(0xFFE0E5ED)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account? ",
                      style: TextStyle(color: muted, fontSize: 13),
                    ),
                    GestureDetector(
                      onTap: _isLoading ? null : _openRegisterScreen,
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          color: navy,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
