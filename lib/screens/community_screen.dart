import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:vanta_app/screens/create_post_screen.dart';
import 'package:vanta_app/screens/post_detail_screen.dart';
import 'member_requests_screen.dart';

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

    /// 🔥 STREAM COMMUNITY FIRST (IMPORTANT)
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('communities')
          .doc(communityId)
          .snapshots(),

      builder: (context, communitySnapshot) {
        if (!communitySnapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final community =
            communitySnapshot.data!.data() as Map<String, dynamic>;

        final visibility = community['visibility'] ?? 'public';
        final adminId = community['adminId'];

        /// 🔥 MEMBER STREAM
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('communities')
              .doc(communityId)
              .collection('members')
              .doc(uid)
              .snapshots(),

          builder: (context, memberSnapshot) {
            final memberExists = memberSnapshot.data?.exists ?? false;
            final memberData =
                memberSnapshot.data?.data() as Map<String, dynamic>?;

            final status = memberData?['status'];
            final role = memberData?['role'];

            final isAdmin = role == 'admin';
            final isApproved = status == 'approved';

            /// 🔥 PRIVATE GATE
            if (visibility == 'private' && !isApproved) {
              return _PrivateGate(
                communityName: communityName,
                communityId: communityId,
                isPending: status == 'pending',
              );
            }

            /// 🔥 MAIN COMMUNITY
            return Scaffold(
              appBar: AppBar(
                title: Text(communityName),

                actions: [
                  /// ADMIN BADGE 😄
                  if (isAdmin)
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('communities')
                          .doc(communityId)
                          .collection('members')
                          .where('status', isEqualTo: 'pending')
                          .snapshots(),
                      builder: (context, snapshot) {
                        final count = snapshot.data?.docs.length ?? 0;

                        return Stack(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.notifications),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MemberRequestsScreen(
                                      communityId: communityId,
                                    ),
                                  ),
                                );
                              },
                            ),

                            if (count > 0)
                              Positioned(
                                right: 6,
                                top: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 18,
                                    minHeight: 18,
                                  ),
                                  child: Text(
                                    "$count",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),

                  /// LEAVE
                  if (memberExists && !isAdmin)
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'leave') {
                          final confirm = await showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text("Leave Community?"),
                              content: const Text(
                                "You must request again to rejoin.",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
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

                          await FirebaseFirestore.instance
                              .collection('communities')
                              .doc(communityId)
                              .collection('members')
                              .doc(uid)
                              .delete();

                          await FirebaseFirestore.instance
                              .collection('communities')
                              .doc(communityId)
                              .update({
                                'memberCount': FieldValue.increment(-1),
                              });

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
              floatingActionButton: isApproved
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
                      
                        final status = visibility == 'private'
                            ? 'pending'
                            : 'approved';

                        await FirebaseFirestore.instance
                            .collection('communities')
                            .doc(communityId)
                            .collection('members')
                            .doc(user.uid)
                            .set({
                              'userId': user.uid,
                              'role': 'member',
                              'status': status,
                              'name':
                                  user.displayName ??
                                  user.email?.split('@')[0] ??
                                  'User',
                              'email': user.email ?? '',
                              'photoUrl': user.photoURL,
                              'joinedAt': FieldValue.serverTimestamp(),
                            }, SetOptions(merge: true));

                        if (status == 'approved') {
                          await FirebaseFirestore.instance
                              .collection('communities')
                              .doc(communityId)
                              .update({'memberCount': FieldValue.increment(1)});
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              status == 'pending'
                                  ? "Request sent. Waiting for admin approval."
                                  : "Welcome to the community 🎉",
                            ),
                          ),
                        );
                      },
                    ),

              /// 🔥 POSTS (FETCH AFTER GATE)
              body: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('communities')
                    .doc(communityId)
                    .collection('posts')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),

                builder: (context, snapshot) {
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

                        onTap: () {
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
      },
    );
  }
}

class _PrivateGate extends StatelessWidget {
  const _PrivateGate({
    required this.communityName,
    required this.communityId,
    required this.isPending,
  });

  final String communityName;
  final String communityId;
  final bool isPending;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: Text(communityName)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isPending ? Icons.hourglass_top : Icons.lock, size: 70),

              const SizedBox(height: 20),

              Text(
                isPending
                    ? "Waiting for admin approval"
                    : "This is a private community 🔒",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              if (!isPending)
                const Text(
                  "Join to see posts and participate in discussions.",
                  textAlign: TextAlign.center,
                ),

              const SizedBox(height: 30),

              if (!isPending)
              
                SizedBox(
                  width: 220,
                  height: 50,
                  child: ElevatedButton(
                    child: const Text("Request to Join"),
                    onPressed: () async {
                      final user = FirebaseAuth.instance.currentUser!;
                     await FirebaseFirestore.instance
    .collection('communities')
    .doc(communityId)
    .collection('members')
    .doc(uid)
    .set({
  'userId': uid,
  'role': 'member',
  'status': 'pending',
  'name': user.displayName 
      ?? user.email?.split('@')[0] 
      ?? 'User',
  'email': user.email ?? '',
  'photoUrl': user.photoURL,
  'joinedAt': FieldValue.serverTimestamp(),
}, SetOptions(merge: true));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Request sent to admin 👍"),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
