import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadProfileImage({
    required String userId,
    required File imageFile,
  }) async {
    final imageRef = _storage
        .ref()
        .child('profile_images')
        .child('$userId${_getFileExtension(imageFile.path)}');

    final extension = _getFileExtension(imageFile.path);
    final metadata = SettableMetadata(
      contentType: extension == '.png' ? 'image/png': 'image/jpeg',
    );

    await imageRef.putFile(imageFile, metadata);

    return await imageRef.getDownloadURL();
  }

  String _getFileExtension(String path) {
    final dotIndex = path.lastIndexOf('.');
    if (dotIndex == -1) return '.jpg';
    return path.substring(dotIndex).toLowerCase();
  }
}
