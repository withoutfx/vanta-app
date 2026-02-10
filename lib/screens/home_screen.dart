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
            MaterialPageRoute(
              builder: (_) => const CreateCommunityScreen(),
            ),
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
            return const Center(
              child: Text("Belum ada komunitas 😄"),
            );
          }

          final communities = snapshot.data!.docs;

          return ListView.builder(
            itemCount: communities.length,
            itemBuilder: (context, index) {

              final community =
                  communities[index].data() as Map<String, dynamic>;

              final communityId = communities[index].id;

              return ListTile(
                title: Text(community['name'] ?? 'No Name'),
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

                    // ✅ kalau sudah join
                    if (memberSnapshot.hasData &&
                        memberSnapshot.data!.exists) {
                      return const Text(
                        "Joined",
                        style: TextStyle(color: Colors.green),
                      );
                    }

                    // ✅ kalau belum join
                    return ElevatedButton(
                      child: const Text("Join"),
                      onPressed: () async {

                        final memberRef = FirebaseFirestore.instance
                            .collection('communities')
                            .doc(communityId)
                            .collection('members')
                            .doc(user.uid);

                        final fallbackName =
                            user.displayName ??
                            user.email!.split('@')[0];

                        await memberRef.set({
                          'name': fallbackName,
                          'email': user.email,
                          'photoUrl': user.photoURL,
                          'joinedAt': FieldValue.serverTimestamp(),
                        });

                        await FirebaseFirestore.instance
                            .collection('communities')
                            .doc(communityId)
                            .update({
                          'memberCount': FieldValue.increment(1),
                        });
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
