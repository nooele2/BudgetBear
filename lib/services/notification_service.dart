import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';




class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;




  String get userId {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    return user.uid;
  }




  // Check budget and create notifications
  Future<void> checkBudgetAndNotify({
    required int year,
    required int month,
    required double spent,
    required double budget,
  }) async {
    if (budget <= 0) return;




    final percentage = (spent / budget) * 100;




    // Determine notification level and create notification
    if (percentage >= 100) {
      // Budget exceeded
      await _createNotification(
        year: year,
        month: month,
        spent: spent,
        budget: budget,
        percentage: percentage,
        title: "Budget Exceeded!",
        message: "Budget exceeded! You've spent ฿${spent.toStringAsFixed(2)}, which is ${percentage.toStringAsFixed(1)}% of your monthly budget. Time to review your finances.",
        level: 'danger',
        thresholdType: 'exceeded',
      );
    } else if (percentage >= 90) {
      // 90% or more
      await _createNotification(
        year: year,
        month: month,
        spent: spent,
        budget: budget,
        percentage: percentage,
        title: "Budget Warning: ${percentage.toStringAsFixed(1)}%",
        message: "Alert! You've used ${percentage.toStringAsFixed(1)}% of your budget. You've spent ฿${spent.toStringAsFixed(2)}. Please be mindful of your expenses.",
        level: 'warning',
        thresholdType: 'warning',
      );
    } else if (percentage >= 80) {
      // 80% or more
      await _createNotification(
        year: year,
        month: month,
        spent: spent,
        budget: budget,
        percentage: percentage,
        title: "Budget Alert: ${percentage.toStringAsFixed(1)}%",
        message: "You've used ${percentage.toStringAsFixed(1)}% of your budget for this month. You've spent ฿${spent.toStringAsFixed(2)}. Consider reviewing your spending.",
        level: 'caution',
        thresholdType: 'caution',
      );
    }
  }




  // Create new notification (always creates, never updates)
  Future<void> _createNotification({
    required int year,
    required int month,
    required double spent,
    required double budget,
    required double percentage,
    required String title,
    required String message,
    required String level,
    required String thresholdType,
  }) async {
    try {
      // Always create a new notification
      await _db
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'title': title,
        'message': message,
        'level': level, // caution, warning, danger
        'percentage': percentage,
        'spent': spent,
        'budget': budget,
        'year': year,
        'month': month,
        'thresholdType': thresholdType, // caution, warning, exceeded
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ Notification created in Firestore: $title');
    } catch (e) {
      print('❌ Error creating notification: $e');
    }
  }




  // Get all notifications stream
  Stream<List<Map<String, dynamic>>> getNotificationsStream() {
    return _db
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }




  // Get unread count
  Stream<int> getUnreadCountStream() {
    return _db
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }




  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }




  // Mark multiple notifications as read
  Future<void> markMultipleAsRead(List<String> notificationIds) async {
    try {
      final batch = _db.batch();
      for (final id in notificationIds) {
        final ref = _db
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .doc(id);
        batch.update(ref, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      print('Error marking notifications as read: $e');
    }
  }




  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }




  // Delete multiple notifications
  Future<void> deleteMultiple(List<String> notificationIds) async {
    try {
      final batch = _db.batch();
      for (final id in notificationIds) {
        final ref = _db
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .doc(id);
        batch.delete(ref);
      }
      await batch.commit();
    } catch (e) {
      print('Error deleting notifications: $e');
    }
  }
}



