import 'package:firebase_auth/firebase_auth.dart';
import 'user_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  Future<UserCredential> register(
    String email,
    String password, {
    required String fullName,
    required String username,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;

    if (user == null) {
      throw StateError('Account creation failed.');
    }

    try {
      await user.updateDisplayName(fullName.trim());

      await _userService.createRegistrationProfile(
        uid: user.uid,
        displayName: fullName.trim(),
        username: username.trim().toLowerCase(),
      );
      await user.sendEmailVerification();

      return credential;
    } catch (e) {
      // Remove the newly created Auth account if profile creation fails.
      try {
        await user.delete();
      } catch (_) {
        // Preserve the original error.
      }

      if (e is UsernameAlreadyInUseException) {
        throw FirebaseAuthException(
          code: 'username-already-in-use',
          message: 'This username is already taken.',
        );
      }

      rethrow;
    }
  }

  Future<UserCredential> login(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> signInAnonymously() async {
    return await _auth.signInAnonymously();
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('No user is signed in.');
    }

    await user.sendEmailVerification();
  }

  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  Future<void> logout() async {
    await _auth.signOut();
  }

  Stream<User?> get authStateChanges {
    return _auth.authStateChanges();
  }
}
