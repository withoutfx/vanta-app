import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreatePostScreen extends StatefulWidget {

  final String communityId;

  const CreatePostScreen({
    super.key,
    required this.communityId,
  });

  @override
  State<CreatePostScreen> createState() =>
      _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {

  final TextEditingController postController =
      TextEditingController();

  bool isLoading = false;

  Future<void> createPost() async {

    final text = postController.text.trim();

    if (text.isEmpty) return;

    setState(() => isLoading = true);

    final user = FirebaseAuth.instance.currentUser!;

    await FirebaseFirestore.instance
        .collection('communities')
        .doc(widget.communityId)
        .collection('posts')
        .add({
      'text': text,
      'authorId': user.uid,
      'authorName': user.displayName,
      'createdAt': FieldValue.serverTimestamp(),
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Post')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            TextField(
              controller: postController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: "What's happening?",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: isLoading ? null : createPost,
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text("Post"),
            )
          ],
        ),
      ),
    );
  }
}
