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

  // Check budget and create notifications (with duplicate prevention)
  Future<void> checkBudgetAndNotify({
    required int year,
    required int month,
    required double spent,
    required double budget,
  }) async {
    if (budget <= 0) return;

    final percentage = (spent / budget) * 100;

    // Only proceed if percentage is 80% or above
    if (percentage < 80) {
      print('ℹ️ Spending at ${percentage.toStringAsFixed(1)}% - below 80% threshold');
      return;
    }

    // Check if a notification with this percentage already exists
    final exists = await _notificationExistsForPercentage(
      year: year,
      month: month,
      percentage: percentage,
    );

    if (exists) {
      print('ℹ️ Notification already exists for ${percentage.toStringAsFixed(1)}% - skipping duplicate');
      return;
    }

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
        level: 'warning',
        thresholdType: 'warning',
      );
    }
  }

  // Check if a notification with this percentage already exists for this month
  Future<bool> _notificationExistsForPercentage({
    required int year,
    required int month,
    required double percentage,
  }) async {
    try {
      final querySnapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('year', isEqualTo: year)
          .where('month', isEqualTo: month)
          .get();

      // Check if any notification has the same percentage (within 0.1% tolerance)
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final existingPercentage = data['percentage'] as double?;
        if (existingPercentage != null && 
            (percentage - existingPercentage).abs() < 0.1) {
          return true;
        }
      }
      return false;
    } catch (e) {
      print('❌ Error checking percentage existence: $e');
      return false;
    }
  }

  // Create notification
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
      await _db
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'title': title,
        'message': message,
        'level': level, // warning, danger
        'percentage': percentage,
        'spent': spent,
        'budget': budget,
        'year': year,
        'month': month,
        'thresholdType': thresholdType, // warning, exceeded
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('✅ Notification created: $title (${percentage.toStringAsFixed(1)}%)');
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

  // Delete old notifications for a month (useful when budget is reset)
  Future<void> deleteNotificationsForMonth({
    required int year,
    required int month,
  }) async {
    try {
      final querySnapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('year', isEqualTo: year)
          .where('month', isEqualTo: month)
          .get();

      final batch = _db.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      print('✅ Deleted notifications for $month/$year (budget reset)');
    } catch (e) {
      print('❌ Error deleting month notifications: $e');
    }
  }

  // Clear all old notifications when a new month starts
  Future<void> cleanupOldMonthNotifications() async {
    try {
      final now = DateTime.now();
      final currentYear = now.year;
      final currentMonth = now.month;

      final querySnapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .get();

      final batch = _db.batch();
      int deleteCount = 0;

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final year = data['year'] as int?;
        final month = data['month'] as int?;

        // Delete notifications from previous months
        if (year != null && month != null) {
          if (year < currentYear || (year == currentYear && month < currentMonth)) {
            batch.delete(doc.reference);
            deleteCount++;
          }
        }
      }

      if (deleteCount > 0) {
        await batch.commit();
        print('✅ Cleaned up $deleteCount old notifications');
      }
    } catch (e) {
      print('❌ Error cleaning up old notifications: $e');
    }
  }
}