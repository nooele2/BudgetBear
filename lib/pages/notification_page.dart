import 'package:flutter/material.dart';
import 'package:budget_bear/services/notification_service.dart';
import 'package:budget_bear/widgets/bottom_nav_bar.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final NotificationService _notificationService = NotificationService();
  
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};
  bool _isAllSelected = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF333333);
    final subtextColor = isDark ? Colors.white70 : Colors.grey.shade700;
    const accent = Color.fromRGBO(71, 168, 165, 1);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          _isSelectionMode 
              ? '${_selectedIds.length} selected' 
              : 'Notifications',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: Icon(
                _isAllSelected 
                    ? Icons.check_box 
                    : Icons.check_box_outline_blank,
                color: accent,
              ),
              onPressed: _selectAll,
              tooltip: 'Select All',
            ),
            IconButton(
              icon: const Icon(Icons.mark_email_read, color: accent),
              onPressed: _selectedIds.isNotEmpty ? _markSelectedAsRead : null,
              tooltip: 'Mark as Read',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _selectedIds.isNotEmpty ? _deleteSelected : null,
              tooltip: 'Delete',
            ),
            IconButton(
              icon: Icon(Icons.close, color: accent),
              onPressed: () {
                setState(() {
                  _isSelectionMode = false;
                  _selectedIds.clear();
                  _isAllSelected = false;
                });
              },
            ),
          ] else
            IconButton(
              icon: const Icon(Icons.checklist, color: accent),
              onPressed: () {
                setState(() {
                  _isSelectionMode = true;
                });
              },
              tooltip: 'Select',
            ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _notificationService.getNotificationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 80,
                    color: subtextColor.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: subtextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You\'ll be notified when you reach over\n80% of your budget limits.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: subtextColor.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final notificationId = notification['id'] as String;
              final isRead = notification['isRead'] ?? false;
              final isSelected = _selectedIds.contains(notificationId);
              final level = notification['level'] ?? 'caution';

              return _buildNotificationCard(
                notificationId: notificationId,
                title: notification['title'] ?? 'Budget Alert',
                message: notification['message'] ?? '',
                level: level,
                isRead: isRead,
                isSelected: isSelected,
                createdAt: notification['createdAt'] as Timestamp?,
                cardColor: cardColor,
                textColor: textColor,
                subtextColor: subtextColor,
                isDark: isDark,
              );
            },
          );
        },
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 3),
    );
  }

  Widget _buildNotificationCard({
    required String notificationId,
    required String title,
    required String message,
    required String level,
    required bool isRead,
    required bool isSelected,
    required Timestamp? createdAt,
    required Color cardColor,
    required Color textColor,
    required Color subtextColor,
    required bool isDark,
  }) {
    final iconData = _getIconForLevel(level);
    final color = _getColorForLevel(level);
    final label = _getLabelForLevel(level);

    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) {
          _toggleSelection(notificationId);
        } else if (!isRead) {
          _notificationService.markAsRead(notificationId);
        }
      },
      onLongPress: () {
        if (!_isSelectionMode) {
          setState(() {
            _isSelectionMode = true;
            _selectedIds.add(notificationId);
          });
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isRead 
              ? cardColor 
              : (isDark 
                  ? const Color(0xFF2A2A2A) 
                  : const Color(0xFFF0F8FF)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? const Color.fromRGBO(71, 168, 165, 1) 
                : Colors.transparent,
            width: 2,
          ),
          boxShadow: cardColor == Colors.white
              ? [
                  const BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isSelectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    color: isSelected 
                        ? const Color.fromRGBO(71, 168, 165, 1) 
                        : subtextColor,
                  ),
                ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(iconData, color: color, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color.fromRGBO(71, 168, 165, 1),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 14,
                        color: subtextColor,
                        height: 1.4,
                      ),
                    ),
                    if (createdAt != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        DateFormat('MMM dd, yyyy • hh:mm a').format(createdAt.toDate()),
                        style: TextStyle(
                          fontSize: 12,
                          color: subtextColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!_isSelectionMode)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: subtextColor),
                  onSelected: (value) {
                    if (value == 'read') {
                      _notificationService.markAsRead(notificationId);
                    } else if (value == 'delete') {
                      _deleteNotification(notificationId);
                    }
                  },
                  itemBuilder: (context) => [
                    if (!isRead)
                      const PopupMenuItem(
                        value: 'read',
                        child: Row(
                          children: [
                            Icon(Icons.mark_email_read, size: 20),
                            SizedBox(width: 8),
                            Text('Mark as read'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForLevel(String level) {
    switch (level) {
      case 'caution':
        return Icons.warning_amber_rounded;
      case 'warning':
        return Icons.error_outline_rounded;
      case 'danger':
        return Icons.dangerous_rounded;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForLevel(String level) {
    switch (level) {
      case 'caution':
        return Colors.amber;
      case 'warning':
        return Colors.orange;
      case 'danger':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getLabelForLevel(String level) {
    switch (level) {
      case 'caution':
        return 'over 80% Alert';
      case 'warning':
        return 'over 90% Warning';
      case 'danger':
        return 'Budget Exceeded';
      default:
        return 'Notification';
    }
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        _isAllSelected = false;
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll() {
    setState(() {
      // Get all notification IDs from the stream
      _notificationService.getNotificationsStream().first.then((notifications) {
        setState(() {
          if (_selectedIds.length == notifications.length) {
            // If all are selected, deselect all
            _selectedIds.clear();
            _isAllSelected = false;
          } else {
            // Select all
            _selectedIds.clear();
            for (var notification in notifications) {
              _selectedIds.add(notification['id'] as String);
            }
            _isAllSelected = true;
          }
        });
      });
    });
  }

  Future<void> _markSelectedAsRead() async {
    await _notificationService.markMultipleAsRead(_selectedIds.toList());
    setState(() {
      _selectedIds.clear();
      _isSelectionMode = false;
      _isAllSelected = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Marked as read')),
      );
    }
  }

  Future<void> _deleteSelected() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notifications'),
        content: Text(
          'Delete ${_selectedIds.length} notification(s)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _notificationService.deleteMultiple(_selectedIds.toList());
      setState(() {
        _selectedIds.clear();
        _isSelectionMode = false;
        _isAllSelected = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notifications deleted')),
        );
      }
    }
  }

  Future<void> _deleteNotification(String id) async {
    await _notificationService.deleteNotification(id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification deleted')),
      );
    }
  }
}