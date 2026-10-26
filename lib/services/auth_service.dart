import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserCredential> register(
    String email,
    String password,
  ) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> login(
    String email,
    String password,
  ) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> resetPassword(String email) async{
    await _auth.sendPasswordResetEmail(
      email: email.trim()
    );
  }

  Future<void> logout() async{
    await _auth.signOut();
  }

  Stream<User?> get authStateChanges {
    return _auth.authStateChanges();
  }
}