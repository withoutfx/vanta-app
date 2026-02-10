import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommunityService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> createCommunity(String name) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception("User not logged in");
    }

    // create community doc
    final communityRef = await _db.collection('communities').add({
      'name': name,
      'ownerId': user.uid,
      'privacyType': 'public',
      'memberCount': 1,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // insert membership
    await _db.collection('community_members').add({
      'communityId': communityRef.id,
      'userId': user.uid,
      'role': 'owner',
      'joinedAt': FieldValue.serverTimestamp(),
    });
  }
}
