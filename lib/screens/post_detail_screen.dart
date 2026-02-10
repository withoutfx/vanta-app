import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostDetailScreen extends StatefulWidget {
  final String communityId;
  final String postId;
  final String postText;
  final String authorName;

  const PostDetailScreen({
    super.key,
    required this.communityId,
    required this.postId,
    required this.postText,
    required this.authorName,
  });

  @override
  State<PostDetailScreen> createState() =>
      _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {

  final controller = TextEditingController();

  CollectionReference get commentsRef =>
      FirebaseFirestore.instance
          .collection('communities')
          .doc(widget.communityId)
          .collection('posts')
          .doc(widget.postId)
          .collection('comments');

  /// 🔥 SEND COMMENT / REPLY
  Future<void> sendComment({String? parentId}) async {

    final text = controller.text.trim();
    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser!;

    await commentsRef.add({
      'text': text,
      'authorId': user.uid,
      'authorName': user.displayName ?? user.email,
      'createdAt': FieldValue.serverTimestamp(),
      'parentId': parentId,
      'depth': parentId == null ? 0 : 1,
    });

    controller.clear();
  }

  @override
  Widget build(BuildContext context) {

    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(title: const Text("Discussion")),

      body: Column(
        children: [

          /// 🔥 POST CARD
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.black12,
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                Text(widget.authorName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold)),

                const SizedBox(height: 8),

                Text(widget.postText),
              ],
            ),
          ),

          /// 🔥 COMMENT LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: commentsRef
                  .where('depth', isEqualTo: 0)
                  .orderBy('createdAt')
                  .snapshots(),
              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                final comments = snapshot.data!.docs;

                if (comments.isEmpty) {
                  return const Center(
                      child: Text("No comments yet"));
                }

                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {

                    final comment =
                        comments[index].data()
                            as Map<String, dynamic>;

                    final commentId =
                        comments[index].id;

                    return Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [

                        /// ⭐ MAIN COMMENT
                        ListTile(
                          title:
                              Text(comment['authorName']),
                          subtitle:
                              Text(comment['text']),
                        ),

                        /// 🔥 REPLIES
                        StreamBuilder<QuerySnapshot>(
                          stream: commentsRef
                              .where('parentId',
                                  isEqualTo: commentId)
                              .orderBy('createdAt')
                              .snapshots(),
                          builder:
                              (context, replySnap) {

                            if (!replySnap.hasData) {
                              return const SizedBox();
                            }

                            final replies =
                                replySnap.data!.docs;

                            return Padding(
                              padding:
                                  const EdgeInsets.only(
                                      left: 40),
                              child: Container(
                                decoration:
                                    const BoxDecoration(
                                  border: Border(
                                    left: BorderSide(
                                      color: Colors.grey,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  children:
                                      replies.map((r) {

                                    final data =
                                        r.data()
                                            as Map<String,
                                                dynamic>;

                                    return ListTile(
                                      dense: true,
                                      title: Text(
                                          data['authorName']),
                                      subtitle:
                                          Text(data['text']),
                                    );

                                  }).toList(),
                                ),
                              ),
                            );
                          },
                        ),

                        /// 🔥 REPLY BUTTON (ONLY DEPTH 0)
                        Padding(
                          padding:
                              const EdgeInsets.only(
                                  left: 16),
                          child: TextButton(
                            child: const Text("Reply"),
                            onPressed: () {

                              final replyController =
                                  TextEditingController();

                              showDialog(
                                context: context,
                                builder: (_) {

                                  return AlertDialog(
                                    title:
                                        const Text("Reply"),
                                    content: TextField(
                                      controller:
                                          replyController,
                                      decoration:
                                          const InputDecoration(
                                        hintText:
                                            "Write a reply...",
                                      ),
                                    ),
                                    actions: [

                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(
                                                context),
                                        child:
                                            const Text(
                                                "Cancel"),
                                      ),

                                      TextButton(
                                        onPressed: () async {

                                          final text =
                                              replyController
                                                  .text
                                                  .trim();

                                          if (text
                                              .isEmpty) return;

                                          await commentsRef
                                              .add({
                                            'text': text,
                                            'authorId':
                                                user.uid,
                                            'authorName': user
                                                    .displayName ??
                                                user.email,
                                            'createdAt':
                                                FieldValue
                                                    .serverTimestamp(),
                                            'parentId':
                                                commentId,
                                            'depth': 1,
                                          });

                                          Navigator.pop(
                                              context);
                                        },
                                        child:
                                            const Text(
                                                "Send"),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ),

                        const Divider(),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          /// 🔥 JOIN CHECK → COMMENT BOX / JOIN BUTTON
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('communities')
                .doc(widget.communityId)
                .collection('members')
                .doc(user.uid)
                .snapshots(),
            builder: (context, snapshot) {

              /// ✅ NOT MEMBER
              if (!snapshot.hasData ||
                  !snapshot.data!.exists) {

                return SafeArea(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(12),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize:
                            const Size.fromHeight(50),
                      ),
                      onPressed: () async {

                        await FirebaseFirestore
                            .instance
                            .collection('communities')
                            .doc(widget.communityId)
                            .collection('members')
                            .doc(user.uid)
                            .set({
                          'name': user.displayName,
                          'email': user.email,
                          'photoUrl': user.photoURL,
                          'joinedAt': FieldValue
                              .serverTimestamp(),
                        });

                        await FirebaseFirestore
                            .instance
                            .collection('communities')
                            .doc(widget.communityId)
                            .update({
                          'memberCount':
                              FieldValue.increment(1)
                        });
                      },
                      child: const Text(
                          "Join to comment"),
                    ),
                  ),
                );
              }

              /// ✅ MEMBER → SHOW COMMENT BOX
              return SafeArea(
                child: Row(
                  children: [

                    Expanded(
                      child: Padding(
                        padding:
                            const EdgeInsets.all(8),
                        child: TextField(
                          controller: controller,
                          decoration:
                              const InputDecoration(
                            hintText:
                                "Write a comment...",
                            border:
                                OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ),

                    IconButton(
                      icon:
                          const Icon(Icons.send),
                      onPressed: () =>
                          sendComment(),
                    ),
                  ],
                ),
              );
            },
          )
        ],
      ),
    );
  }
}
