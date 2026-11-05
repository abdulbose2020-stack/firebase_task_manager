import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/user_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final userService = UserService();

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
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

        return StreamBuilder(
          key: ValueKey(user.uid),
          stream: userService.watchProfile(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState ==
                    ConnectionState.waiting ||
                !profileSnapshot.hasData ||
                !profileSnapshot.data!.exists) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final profile =
                profileSnapshot.data!.data() ?? <String, dynamic>{};

            return HomeScreen(initialProfile: profile);
          },
        );
      },
    );
  }
}