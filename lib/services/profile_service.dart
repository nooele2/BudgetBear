import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Get current user's profile data
  Future<Map<String, String>> getUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      return {'name': '', 'email': ''};
    }

    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      return {
        'name': doc.data()?['name'] ?? '',
        'email': user.email ?? '',
      };
    } catch (e) {
      print('Error loading profile: $e');
      return {'name': '', 'email': user.email ?? ''};
    }
  }

  /// Update user profile
  Future<bool> updateUserProfile({
    required String name,
    String? photoUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      await _db.collection('users').doc(user.uid).update({
        'name': name,
        if (photoUrl != null) 'photoUrl': photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }

  /// Get current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// Check if user is logged in
  bool isUserLoggedIn() {
    return _auth.currentUser != null;
  }
}