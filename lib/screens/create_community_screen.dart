import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateCommunityScreen extends StatefulWidget {
  const CreateCommunityScreen({super.key});

  @override
  State<CreateCommunityScreen> createState() =>
      _CreateCommunityScreenState();
}

class _CreateCommunityScreenState
    extends State<CreateCommunityScreen> {

  final nameController = TextEditingController();
  final descController = TextEditingController();

  String visibility = 'public';
  bool isLoading = false;

  Future<void> createCommunity() async {

    final name = nameController.text.trim();
    final description = descController.text.trim();

    if (name.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Name and description are required"),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {

      final user = FirebaseAuth.instance.currentUser!;

      /// 🔥 ANTI-SPAM LIMIT
      final ownedCommunities = await FirebaseFirestore.instance
          .collection('communities')
          .where('adminId', isEqualTo: user.uid)
          .get();

      if (ownedCommunities.docs.length >= 5) {
        throw Exception(
            "You’ve reached the maximum number of communities.");
      }

      final communityRef = FirebaseFirestore.instance
          .collection('communities')
          .doc();

      /// 🔥 TRANSACTION (ANTI RACE CONDITION)
      await FirebaseFirestore.instance.runTransaction((tx) async {

        tx.set(communityRef, {
          'name': name,
          'description': description,
          'adminId': user.uid,
          'visibility': visibility, // public | private
          'affiliateId': null, // future ready
          'memberCount': 1,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        /// INSERT ADMIN AS MEMBER
        tx.set(
          communityRef
              .collection('members')
              .doc(user.uid),
          {
            'userId': user.uid,
            'role': 'admin',
            'status': 'approved',
            'joinedAt': FieldValue.serverTimestamp(),
          },
        );
      });

      if (!mounted) return;

      Navigator.pop(context);

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll("Exception:", ""),
          ),
        ),
      );

    } finally {

      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Community'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// COMMUNITY NAME
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Community Name',
              ),
            ),

            const SizedBox(height: 16),

            /// DESCRIPTION
            TextField(
              controller: descController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
              ),
            ),

            const SizedBox(height: 24),

            /// VISIBILITY TITLE
            const Text(
              "Community Type",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            /// PUBLIC
            RadioListTile(
              title: const Text("Public"),
              subtitle: const Text(
                  "Anyone can view and join instantly."),
              value: 'public',
              groupValue: visibility,
              onChanged: (val) {
                setState(() => visibility = val!);
              },
            ),

            /// PRIVATE
            RadioListTile(
              title: const Text("Private"),
              subtitle: const Text(
                  "Requires admin approval before joining."),
              value: 'private',
              groupValue: visibility,
              onChanged: (val) {
                setState(() => visibility = val!);
              },
            ),

            const SizedBox(height: 32),

            /// CREATE BUTTON
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : createCommunity,
                child: isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : const Text("Create Community"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
