import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'waiting_screen.dart';
import 'video_feed_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<bool> checkApproval(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (!doc.exists) return false;

    return doc['isApproved'] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // belum login
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Belum login")),
      );
    }

    return FutureBuilder(
      future: checkApproval(user.uid),
      builder: (context, snapshot) {
        // loading
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final approved = snapshot.data!;

        if (approved) {
          return const VideoFeedScreen();
        } else {
          return const WaitingScreen();
        }
      },
    );
  }
}
