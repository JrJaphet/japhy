import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class ProfileService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  Future<void> uploadProfilePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    File file = File(pickedFile.path);
    final user = _auth.currentUser!;
    final ref = _storage.ref().child('profile_images/${user.uid}.jpg');

    await ref.putFile(file);
    final downloadUrl = await ref.getDownloadURL();

    await _firestore.collection('users').doc(user.uid).set({
      'profileImageUrl': downloadUrl,
    }, SetOptions(merge: true));
  }

  Future<String?> getProfileImageUrl() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final ref = _storage.ref('profile_images/${user.uid}.jpg');
      return await ref.getDownloadURL();
    } catch (_) {
      return null;
    }
  }
}
