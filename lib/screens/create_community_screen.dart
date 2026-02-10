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

  final TextEditingController nameController =
      TextEditingController();

  bool isLoading = false;

  Future<void> createCommunity() async {

    final name = nameController.text.trim();

    if (name.isEmpty) return;

    setState(() => isLoading = true);

    final user = FirebaseAuth.instance.currentUser!;

    final doc =
        FirebaseFirestore.instance.collection('communities').doc();

    await doc.set({
      'name': name,
      'ownerId': user.uid,
      'memberCount': 1,
      'createdAt': FieldValue.serverTimestamp(),
      'privacyType': 'public',
    });

    // 🔥 auto join creator
    await doc
        .collection('members')
        .doc(user.uid)
        .set({
      'name': user.displayName,
      'email': user.email,
      'photoUrl': user.photoURL,
      'joinedAt': FieldValue.serverTimestamp(),
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Community')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Community Name',
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: isLoading ? null : createCommunity,
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text("Create"),
            ),
          ],
        ),
      ),
    );
  }
}
