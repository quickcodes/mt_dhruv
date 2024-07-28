import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class ProfileProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<Map<String, dynamic>?> getUserProfile() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(user.uid).get();
      return doc.data() as Map<String, dynamic>?;
    }
    return null;
  }

  Future<void> updateProfile(
      String username, String bio, String profilePictureUrl) async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set({
        'username': username,
        'bio': bio,
        'profilePictureUrl': profilePictureUrl,
      });
    }
  }

  Future<String?> uploadProfileImage(File imageFile) async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        String fileName =
            'profile_images/${user.uid}/${DateTime.now().toIso8601String()}';
        Reference storageRef = _storage.ref().child(fileName);
        UploadTask uploadTask = storageRef.putFile(imageFile);
        TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => {});
        String downloadUrl = await taskSnapshot.ref.getDownloadURL();
        return downloadUrl;
      } catch (e) {
        print('Error uploading profile image: $e');
        return null;
      }
    }
    return null;
  }
}
