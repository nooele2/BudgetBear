import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';




class DeviceNotificationService {
  static final DeviceNotificationService _instance = DeviceNotificationService._internal();
  factory DeviceNotificationService() => _instance;
  DeviceNotificationService._internal();




  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;




  bool _isInitialized = false;
  StreamSubscription? _notificationListener;
  Set<String> _processedNotifications = {};




  /// Initialize the notification service
  /// Call this once when the app starts
  Future<void> initialize() async {
    if (_isInitialized) return;




    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );




    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );




    // Create Android notification channel
    const androidChannel = AndroidNotificationChannel(
      'budget_alerts',
      'Budget Alerts',
      description: 'Notifications for budget warnings and alerts',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );




    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);




    _isInitialized = true;
    print('✅ Local notifications initialized');




    // Start listening automatically if notifications are enabled
    final enabled = await areNotificationsEnabled();
    if (enabled) {
      startListening();
    }
  }




  /// Handle when user taps on a notification
  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // TODO: Navigate to specific page based on payload
  }




  /// Request notification permissions
  Future<bool> requestPermission() async {
    // iOS permissions
    final iosImplementation = _localNotifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();




    if (iosImplementation != null) {
      final granted = await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      
      if (granted == true) {
        print('✅ iOS notification permission granted');
        return true;
      } else {
        print('❌ iOS notification permission denied');
        return false;
      }
    }




    // Android 13+ permissions
    final androidImplementation = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();




    if (androidImplementation != null) {
      final granted = await androidImplementation.requestNotificationsPermission();
      if (granted == true) {
        print('✅ Android notification permission granted');
        return true;
      } else {
        print('❌ Android notification permission denied');
        return false;
      }
    }




    return true; // Default true for older Android versions
  }




  /// Enable device notifications for the current user
  Future<bool> enableNotifications() async {
    final user = _auth.currentUser;
    if (user == null) return false;




    try {
      // Request permission first
      final granted = await requestPermission();
      if (!granted) return false;




      // Update Firestore
      await _db.collection('users').doc(user.uid).update({
        'deviceNotificationsEnabled': true,
        'notificationSettingsUpdatedAt': FieldValue.serverTimestamp(),
      });




      // Start listening
      startListening();




      print('✅ Device notifications enabled');
      return true;
    } catch (e) {
      print('❌ Error enabling notifications: $e');
      return false;
    }
  }




  /// Disable device notifications for the current user
  Future<bool> disableNotifications() async {
    final user = _auth.currentUser;
    if (user == null) return false;




    try {
      // Update Firestore
      await _db.collection('users').doc(user.uid).update({
        'deviceNotificationsEnabled': false,
        'notificationSettingsUpdatedAt': FieldValue.serverTimestamp(),
      });




      // Cancel all pending notifications
      await _localNotifications.cancelAll();




      // Stop listening
      stopListening();




      print('✅ Device notifications disabled');
      return true;
    } catch (e) {
      print('❌ Error disabling notifications: $e');
      return false;
    }
  }




  /// Check if notifications are enabled for the current user
  Future<bool> areNotificationsEnabled() async {
    final user = _auth.currentUser;
    if (user == null) return false;




    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      return doc.data()?['deviceNotificationsEnabled'] ?? false;
    } catch (e) {
      print('❌ Error checking notification status: $e');
      return false;
    }
  }




  /// Send a local notification to the device
  Future<void> sendBudgetNotification({
    required String title,
    required String message,
    required String level, // caution, warning, danger
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;




    // Check if user has enabled device notifications
    final enabled = await areNotificationsEnabled();
    if (!enabled) {
      print('⏭️ Device notifications disabled by user');
      return;
    }




    try {
      // Determine priority based on level
      final priority = _getPriority(level);
      final importance = _getImportance(level);
      final color = _getColor(level);




      final androidDetails = AndroidNotificationDetails(
        'budget_alerts',
        'Budget Alerts',
        channelDescription: 'Notifications for budget warnings and alerts',
        importance: importance,
        priority: priority,
        enableVibration: true,
        playSound: true,
        styleInformation: BigTextStyleInformation(message),
        color: color,
        icon: '@mipmap/ic_launcher',
      );




      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );




      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );




      // Generate unique notification ID
      final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);




      // Show notification
      await _localNotifications.show(
        notificationId,
        title,
        message,
        details,
        payload: level,
      );




      print('✅ Device notification sent: $title');
    } catch (e) {
      print('❌ Error sending device notification: $e');
    }
  }




  /// Start listening to Firestore notifications and send device notifications
  void startListening() {
    final user = _auth.currentUser;
    if (user == null) {
      print('⚠️ Cannot start listening: No user logged in');
      return;
    }




    // Cancel existing listener to prevent duplicates
    stopListening();




    print('👂 Starting notification listener...');




    _notificationListener = _db
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) async {
      print('📬 Received snapshot with ${snapshot.docChanges.length} changes');
      
      // Process only newly added documents
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final doc = change.doc;
          final data = doc.data();
          
          print('🔍 Processing notification ${doc.id}');
          
          // Skip if already processed
          if (_processedNotifications.contains(doc.id)) {
            print('⏭️ Already processed: ${doc.id}');
            continue;
          }




          // Check if this is a new notification (created in last 30 seconds)
          final createdAt = data?['createdAt'] as Timestamp?;
          if (createdAt != null) {
            final diff = DateTime.now().difference(createdAt.toDate());
            print('⏱️ Notification age: ${diff.inSeconds} seconds');
            
            if (diff.inSeconds <= 30) {
              print('🔔 New notification detected (${doc.id})');
              
              // Mark as processed
              _processedNotifications.add(doc.id);
              
              // Send device notification
              await sendBudgetNotification(
                title: data?['title'] ?? 'Budget Alert',
                message: data?['message'] ?? '',
                level: data?['level'] ?? 'caution',
              );
            } else {
              print('⏭️ Notification too old: ${doc.id} (${diff.inSeconds}s)');
            }
          } else {
            print('⚠️ No timestamp found for notification: ${doc.id}');
          }
        }
      }
      
      // Clean up old processed IDs (keep only last 50)
      if (_processedNotifications.length > 50) {
        final list = _processedNotifications.toList();
        _processedNotifications = list.skip(list.length - 50).toSet();
      }
    }, onError: (error) {
      print('❌ Error in notification listener: $error');
    });
  }




  /// Stop listening to Firestore notifications
  void stopListening() {
    _notificationListener?.cancel();
    _notificationListener = null;
    _processedNotifications.clear();
    print('🛑 Stopped notification listener');
  }




  /// Cancel all pending notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
    print('🗑️ All notifications cancelled');
  }




  /// Cancel a specific notification by ID
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }




  /// Dispose and cleanup (call on logout or app close)
  void dispose() {
    stopListening();
    print('🧹 DeviceNotificationService disposed');
  }




  // Helper methods for notification styling
  Priority _getPriority(String level) {
    switch (level) {
      case 'danger':
        return Priority.high;
      case 'warning':
        return Priority.defaultPriority;
      default:
        return Priority.low;
    }
  }




  Importance _getImportance(String level) {
    switch (level) {
      case 'danger':
        return Importance.high;
      case 'warning':
        return Importance.defaultImportance;
      default:
        return Importance.low;
    }
  }




  Color _getColor(String level) {
    switch (level) {
      case 'danger':
        return const Color(0xFFEF5350); // Red
      case 'warning':
        return const Color(0xFFFF9800); // Orange
      default:
        return const Color(0xFFFFC107); // Amber
    }
  }
}



