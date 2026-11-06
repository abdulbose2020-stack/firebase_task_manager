import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/user_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'email_verification_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final userService = UserService();

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        final user = snapshot.data!;

        // Prevent anonymous users from accessing the dashboard.
        if (user.isAnonymous) {
          return const LoginScreen();
        }

        return StreamBuilder(
          key: ValueKey(user.uid),
          stream: userService.watchProfile(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState ==
                    ConnectionState.waiting ||
                !profileSnapshot.hasData ||
                !profileSnapshot.data!.exists) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final profile =
                profileSnapshot.data!.data() ?? <String, dynamic>{};

            final verificationRequired =
                profile['emailVerificationRequired'] as bool? ?? false;

            if (verificationRequired && !user.emailVerified) {
              return const EmailVerificationScreen();
            }

            return HomeScreen(initialProfile: profile);
          },
        );
      },
    );
  }
}
