import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MemberRequestsScreen extends StatelessWidget {
  final String communityId;

  const MemberRequestsScreen({
    super.key,
    required this.communityId,
  });

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Join Requests"),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('communities')
            .doc(communityId)
            .collection('members')
            .where('status', isEqualTo: 'pending')
            .snapshots(),

        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final requests = snapshot.data!.docs;

          if (requests.isEmpty) {
            return const Center(
              child: Text("No pending requests 👍"),
            );
          }

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {

              final doc = requests[index];
              final data =
                  doc.data() as Map<String, dynamic>;

              final userId = doc.id;

              return ListTile(

                /// 🔥 AVATAR (future ready)
                leading: const CircleAvatar(
                  child: Icon(Icons.person),
                ),

                title: Text(
                  data['name'] ?? 'User',
                ),

                subtitle: const Text(
                  "Wants to join this community",
                ),

                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    /// ❌ REJECT
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.red,
                      ),
                      onPressed: () async {

                        await doc.reference.delete();

                      },
                    ),

                    /// ✅ APPROVE
                   IconButton(
  icon: const Icon(
    Icons.check,
    color: Colors.green,
  ),
  onPressed: () async {

    final db = FirebaseFirestore.instance;

    try {

      await db.runTransaction((tx) async {

        final memberRef = db
            .collection('communities')
            .doc(communityId)
            .collection('members')
            .doc(userId);

        final communityRef =
            db.collection('communities').doc(communityId);

        final memberSnap =
            await tx.get(memberRef);

        /// 🔥 VERY IMPORTANT
        /// prevent double approve
        if (!memberSnap.exists) return;

        final data =
            memberSnap.data() as Map<String, dynamic>;

        if (data['status'] == 'approved') return;

        /// ✅ approve
        tx.update(memberRef, {
          'status': 'approved',
          'approvedAt': FieldValue.serverTimestamp(),
        });

        /// ✅ increment member count safely
        tx.update(communityRef, {
          'memberCount': FieldValue.increment(1),
        });

      });

    } catch (e) {

      debugPrint("APPROVE ERROR: $e");

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Failed to approve member",
          ),
        ),
      );
    }
  },
)

                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
