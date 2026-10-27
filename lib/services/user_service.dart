import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final CollectionReference<Map<String, dynamic>> _users = FirebaseFirestore
      .instance
      .collection('users');

  String get _userId {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw StateError('No user is signed in.');
    }

    return user.uid;
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
}
