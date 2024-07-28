

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/post_provider.dart';
import '../widgets/post_widget.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final postProvider = Provider.of<PostProvider>(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('MT Dhruv', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, '/create_post'),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: postProvider.getPosts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
                child: Text('Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.black)));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'No posts available',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
              ),
            );
          }

          List<Map<String, dynamic>> posts = snapshot.data!;
          return FutureBuilder<Map<String, String>>(
            future: _fetchUsernamesForPosts(posts, postProvider),
            builder: (context, usernameSnapshot) {
              if (usernameSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (usernameSnapshot.hasError) {
                return Center(
                    child: Text('Error: ${usernameSnapshot.error}',
                        style: const TextStyle(color: Colors.black)));
              } else if (!usernameSnapshot.hasData) {
                return const Center(
                    child: Text('Error fetching usernames',
                        style: TextStyle(color: Colors.black)));
              }

              Map<String, String> usernames = usernameSnapshot.data!;

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  var post = posts[index];
                  var postId = post['id'];
                  var username = usernames[post['authorId']] ?? 'Unknown';
                  var timestamp = (post['timestamp'] as Timestamp).toDate();

                  return FutureBuilder<bool>(
                    future: postProvider.isPostLiked(postId),
                    builder: (context, likeSnapshot) {
                      bool isLiked = likeSnapshot.data ?? false;
                      return PostWidget(
                        postId: postId,
                        content: post['content'],
                        likes: post['likes'].length,
                        isLiked: isLiked,
                        onLike: () => postProvider.likePost(postId),
                        username: username,
                        timestamp: timestamp,
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<Map<String, String>> _fetchUsernamesForPosts(
      List<Map<String, dynamic>> posts, PostProvider postProvider) async {
    Map<String, String> usernames = {};
    Set<String> userIds =
        posts.map((post) => post['authorId'] as String).toSet();

    for (String userId in userIds) {
      String username = await postProvider.getUsername(userId);
      usernames[userId] = username;
    }

    return usernames;
  }
}
