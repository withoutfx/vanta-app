import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';


import 'package:vanta_app/screens/create_post_screen.dart';
import 'package:vanta_app/screens/post_detail_screen.dart';


class CommunityScreen extends StatelessWidget {
  final String communityId;
  final String communityName;

  const CommunityScreen({
    super.key,
    required this.communityId,
    required this.communityName,
  });

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('communities')
          .doc(communityId)
          .collection('members')
          .doc(uid)
          .snapshots(),

      builder: (context, memberSnapshot) {
        final isMember = memberSnapshot.data?.exists ?? false;

        return Scaffold(
          /// 🔥 APP BAR
          appBar: AppBar(
            title: Text(communityName),

            actions: [
              /// hanya member yang bisa leave
              if (isMember)
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'leave') {
                      final user = FirebaseAuth.instance.currentUser!;

                      final communityDoc = await FirebaseFirestore.instance
                          .collection('communities')
                          .doc(communityId)
                          .get();

                      /// owner gak boleh leave
                      if (communityDoc['ownerId'] == user.uid) {
                        showDialog(
                          context: context,
                          builder: (_) => const AlertDialog(
                            title: Text("You are the owner"),
                            content: Text(
                              "Transfer ownership or delete the community first.",
                            ),
                          ),
                        );

                        return;
                      }

                      final confirm = await showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("Leave Community?"),
                          content: const Text(
                            "Kamu harus join lagi kalau mau masuk.",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text("Leave"),
                            ),
                          ],
                        ),
                      );

                      if (confirm != true) return;

                      /// delete membership
                      await FirebaseFirestore.instance
                          .collection('communities')
                          .doc(communityId)
                          .collection('members')
                          .doc(user.uid)
                          .delete();

                      /// decrement counter
                      await FirebaseFirestore.instance
                          .collection('communities')
                          .doc(communityId)
                          .update({'memberCount': FieldValue.increment(-1)});

                      Navigator.pop(context);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'leave',
                      child: Text("Leave Community"),
                    ),
                  ],
                ),
            ],
          ),

          /// 🔥 FAB SMART
          floatingActionButton: isMember
              ? FloatingActionButton(
                  child: const Icon(Icons.edit),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CreatePostScreen(communityId: communityId),
                      ),
                    );
                  },
                )
              : FloatingActionButton.extended(
                  backgroundColor: Colors.orange,
                  icon: const Icon(Icons.group),
                  label: const Text("Join"),
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser!;

                    await FirebaseFirestore.instance
                        .collection('communities')
                        .doc(communityId)
                        .collection('members')
                        .doc(user.uid)
                        .set({
                          'name': user.displayName,
                          'email': user.email,
                          'photoUrl': user.photoURL,
                          'joinedAt': FieldValue.serverTimestamp(),
                        });

                    await FirebaseFirestore.instance
                        .collection('communities')
                        .doc(communityId)
                        .update({'memberCount': FieldValue.increment(1)});
                  },
                ),

          /// 🔥 POSTS
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('communities')
                .doc(communityId)
                .collection('posts')
                .orderBy('createdAt', descending: true)
                .snapshots(),

            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final posts = snapshot.data!.docs;

              if (posts.isEmpty) {
                return const Center(child: Text("Belum ada post 😄"));
              }

              return ListView.builder(
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index].data() as Map<String, dynamic>;

                  return ListTile(
                    title: Text(post['authorName'] ?? 'User'),

                    subtitle: Text(post['text'] ?? ''),

                    /// nanti klik → comment screen
                    onTap: () {
                      final post = posts[index].data() as Map<String, dynamic>;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PostDetailScreen(
                            communityId: communityId,
                            postId: posts[index].id,
                            postText: post['text'] ?? '',
                            authorName: post['authorName'] ?? 'User',
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
