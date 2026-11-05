import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UsernameAlreadyInUseException implements Exception {}

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _usernames =>
      _firestore.collection('usernames');

  String get _userId {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw StateError('No user is signed in.');
    }

    return user.uid;
  }

  Future<void> createRegistrationProfile({
    required String uid,
    required String displayName,
    required String username,
  }) async {
    final userRef = _users.doc(uid);
    final usernameRef = _usernames.doc(username);

    await _firestore.runTransaction((transaction) async {
      final usernameSnapshot = await transaction.get(usernameRef);

      if (usernameSnapshot.exists) {
        throw UsernameAlreadyInUseException();
      }

      transaction.set(userRef, {
        'uid': uid,
        'displayName': displayName,
        'username': username,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      transaction.set(usernameRef, {
        'uid': uid,
        'username': username,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> saveProfile({
    required String displayName,
    String? profileImageUrl,
  }) async {
    final data = <String, dynamic>{
      'uid': _userId,
      'displayName': displayName,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (profileImageUrl != null) {
      data['profileImageUrl'] = profileImageUrl;
    }

    await _users.doc(_userId).set(data, SetOptions(merge: true));
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getProfile() async {
    return await _users.doc(_userId).get();
  }
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchProfile() {
  return _users.doc(_userId).snapshots();
  }

  Future<void> updateUsername(String newUsername) async {
    final uid = _userId;
    final normalizedUsername = newUsername.trim().toLowerCase();

    final userRef = _users.doc(uid);
    final newUsernameRef = _usernames.doc(normalizedUsername);

    await _firestore.runTransaction((transaction) async {
      final userSnapshot = await transaction.get(userRef);
      final usernameSnapshot = await transaction.get(newUsernameRef);

      if (!userSnapshot.exists) {
        throw Exception('User profile not found.');
      }

      final currentUsername = userSnapshot.data()?['username'] as String? ?? '';

      if (currentUsername == normalizedUsername) return;

      if (usernameSnapshot.exists) {
        throw UsernameAlreadyInUseException();
      }

      if (currentUsername.isNotEmpty) {
        transaction.delete(_usernames.doc(currentUsername));
      }

      transaction.set(newUsernameRef, {
        'uid': uid,
        'username': normalizedUsername,
        'createdAt': FieldValue.serverTimestamp(),
      });

      transaction.update(userRef, {
        'username': normalizedUsername,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
