import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';
import 'community_screen.dart';
import 'create_community_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vanta'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirm = await showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Logout"),
                  content: const Text("Yakin mau logout?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Batal"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Logout"),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await AuthService().signOut();
              }
            },
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateCommunityScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('communities')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Belum ada komunitas 😄"));
          }

          final communities = snapshot.data!.docs;

          return ListView.builder(
            itemCount: communities.length,
            itemBuilder: (context, index) {
              final community =
                  communities[index].data() as Map<String, dynamic>;

              final communityId = communities[index].id;

              return ListTile(
                title: Row(
                  children: [
                    Text(community['name'] ?? 'No Name'),

                    if (community['visibility'] == 'private')
                      const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Icon(Icons.lock, size: 16),
                      ),
                  ],
                ),

                subtitle: Text("Members: ${community['memberCount'] ?? 0}"),

                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CommunityScreen(
                        communityId: communityId,
                        communityName: community['name'],
                      ),
                    ),
                  );
                },

                trailing: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('communities')
                      .doc(communityId)
                      .collection('members')
                      .doc(user.uid)
                      .snapshots(),
                  builder: (context, memberSnapshot) {
                    final visibility = community['visibility'] ?? 'public';

                    /// ✅ SUDAH MEMBER
                    if (memberSnapshot.hasData && memberSnapshot.data!.exists) {
                      final data =
                          memberSnapshot.data!.data() as Map<String, dynamic>?;

                      final status = data?['status'];

                      if (status == 'pending') {
                        return const Text(
                          "Pending",
                          style: TextStyle(color: Colors.orange),
                        );
                      }

                      return const Text(
                        "Joined",
                        style: TextStyle(color: Colors.green),
                      );
                    }

                    /// 🔥 BELUM MEMBER
                    return ElevatedButton(
                      child: Text(visibility == 'private' ? "Request" : "Join"),

                      onPressed: () async {
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
                            });

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
                                  ? "Request sent 👍"
                                  : "Joined community 🎉",
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
