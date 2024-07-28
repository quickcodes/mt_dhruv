import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PostProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String?> getCurrentUsername() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        return userDoc.exists ? userDoc['username'] : null;
      } catch (e) {
        print('Error fetching username: $e');
        return null;
      }
    }
    return null;
  }


  Stream<List<Map<String, dynamic>>> getPosts() {
    return _firestore.collection('posts').orderBy('timestamp', descending: true).snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => {
        'id': doc.id,
        'content': doc['content'],
        'authorId': doc['authorId'],
        'timestamp': doc['timestamp'],
        'likes': List.from(doc['likes'] ?? []),
      }).toList(),
    );
  }

  Future<String?> createPost(String content) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentReference postRef = await _firestore.collection('posts').add({
        'content': content,
        'authorId': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'likes': []
      });
      return postRef.id; 
    }
    return null; 
  }

  Future<void> likePost(String postId) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentReference postRef = _firestore.collection('posts').doc(postId);
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot postSnapshot = await transaction.get(postRef);
        List<dynamic> likes = postSnapshot['likes'] ?? [];
        if (likes.contains(user.uid)) {
          likes.remove(user.uid);
        } else {
          likes.add(user.uid);
        }
        transaction.update(postRef, {'likes': likes});
      });
    }
  }

  Future<bool> isPostLiked(String postId) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot postSnapshot = await _firestore.collection('posts').doc(postId).get();
      List<dynamic> likes = postSnapshot['likes'] ?? [];
      return likes.contains(user.uid);
    }
    return false;
  }
  Future<String> getUsername(String userId) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      return userDoc.exists ? userDoc['username'] ?? 'Unknown' : 'Unknown';
    } catch (e) {
      return 'Error';
    }
  }

}
