import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Real-time user profile
  Stream<DocumentSnapshot> getUserProfile() {
    if (currentUserId == null) throw Exception('User not authenticated');
    return _db.collection('users').doc(currentUserId).snapshots();
  }

  // Update user profile
  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    await _db.collection('users').doc(currentUserId).set(data, SetOptions(merge: true));
  }

  // Real-time chat messages
  Stream<QuerySnapshot> getChatMessages(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots();
  }

  // Send chat message
  Future<void> sendMessage(String chatId, String message) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'text': message,
      'senderId': currentUserId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}