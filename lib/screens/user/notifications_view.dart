import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ionicons/ionicons.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:attendance_tracking/config/api_config.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class NotificationsView extends StatefulWidget {
  final String userId;

  const NotificationsView({super.key, required this.userId});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('Fetching notifications for user: ${widget.userId}');
      final response = await http
          .get(
            Uri.parse(
              '${ApiConfig.baseUrl}/api/notifications/${widget.userId}/',
            ),
            headers: {'Accept': 'application/json'},
          )
          .timeout(Duration(seconds: 5));

      print('Notifications API Response Status: ${response.statusCode}');
      print('Notifications API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> notificationsData = json.decode(response.body);

        setState(() {
          _notifications = notificationsData.map((notif) {
            DateTime timestamp;
            try {
              timestamp = DateTime.parse(
                notif['createdAt'] ??
                    notif['created_at'] ??
                    DateTime.now().toIso8601String(),
              );
            } catch (e) {
              timestamp = DateTime.now();
            }
            return {
              'id': notif['id']?.toString() ?? 'unknown',
              'title': notif['title'] ?? 'Notification',
              'message': notif['description'] ?? notif['message'] ?? '',
              'type': notif['type'] ?? notif['notification_type'] ?? 'info',
              'timestamp': timestamp,
              'isRead': notif['isRead'] ?? notif['is_read'] ?? false,
              'icon': notif['icon'] ?? 'notifications',
              'iconColor':
                  notif['iconColor'] ?? notif['icon_color'] ?? '#3498DB',
              'timeAgo': notif['time'] ?? '',
            };
          }).toList();
          _isLoading = false;
        });
      } else {
        print('Failed to fetch notifications: ${response.statusCode}');
        _useDefaultNotifications();
      }
    } catch (e) {
      print('Error fetching notifications: $e');
      _useDefaultNotifications();
    }
  }

  Future<void> _refreshNotifications() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      await _fetchNotifications();
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  void _useDefaultNotifications() {
    // Use dummy data as fallback
    final List<Map<String, dynamic>> defaultNotifications = [
      {
        'id': '1',
        'title': 'Attendance Marked Successfully',
        'message':
            'Your attendance for Computer Science class has been marked present with 98.5% confidence.',
        'type': 'success',
        'timestamp': DateTime.now().subtract(Duration(minutes: 5)),
        'isRead': false,
        'icon': 'checkmark_circle',
        'iconColor': '#2ECC71',
      },
      {
        'id': '2',
        'title': 'Class Reminder',
        'message':
            'Mathematics class is starting in 15 minutes. Room 305, Building A.',
        'type': 'reminder',
        'timestamp': DateTime.now().subtract(Duration(minutes: 30)),
        'isRead': false,
        'icon': 'time',
        'iconColor': '#3498DB',
      },
      {
        'id': '3',
        'title': 'Low Attendance Alert',
        'message':
            'Your attendance rate is below 75%. Please improve your attendance to avoid academic penalties.',
        'type': 'warning',
        'timestamp': DateTime.now().subtract(Duration(hours: 2)),
        'isRead': false,
        'icon': 'alert_circle',
        'iconColor': '#F39C12',
      },
    ];

    setState(() {
      _notifications = defaultNotifications;
      _isLoading = false;
    });
  }

  void _markAsRead(String id) async {
    try {
      final notificationId = int.tryParse(id);
      if (notificationId != null) {
        await http.post(
          Uri.parse(
            '${ApiConfig.baseUrl}/api/notifications/mark-read/$notificationId/',
          ),
        );
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }

    setState(() {
      final notification = _notifications.firstWhere(
        (notif) => notif['id'] == id,
        orElse: () => {},
      );
      if (notification.isNotEmpty) {
        notification['isRead'] = true;
      }
    });
  }

  void _markAllAsRead() async {
    try {
      await http.post(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/notifications/mark-all-read/${widget.userId}/',
        ),
      );
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }

    setState(() {
      for (var notification in _notifications) {
        notification['isRead'] = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color primaryColor = theme.colorScheme.primary;
    final Color textColor =
        theme.textTheme.bodyLarge?.color ??
        (isDark ? Colors.white : Colors.black87);
    final Color subtleTextColor =
        theme.textTheme.bodySmall?.color ??
        (isDark ? Colors.grey.shade400 : Colors.grey.shade600);

    final unreadCount = _notifications
        .where((n) => n['isRead'] == false)
        .length;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'Notifications',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        actions: [
          IconButton(
            icon: _isRefreshing
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                  )
                : Icon(Ionicons.refresh, color: textColor),
            onPressed: _isRefreshing ? null : _refreshNotifications,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header with Mark All as Read
            if (unreadCount > 0 && !_isLoading)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.grey.shade900
                      : primaryColor.withOpacity(0.05),
                  border: Border(
                    bottom: BorderSide(
                      color: isDark
                          ? Colors.grey.shade800
                          : Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Ionicons.notifications, color: primaryColor, size: 20),
                    SizedBox(width: 8),
                    Text(
                      '$unreadCount unread notification${unreadCount > 1 ? 's' : ''}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                    Spacer(),
                    TextButton(
                      onPressed: _markAllAsRead,
                      child: Text(
                        'Mark all as read',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Notifications List
            Expanded(
              child: _isLoading
                  ? Center(
                      child: SpinKitFadingCircle(
                        color: primaryColor,
                        size: 50.0,
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _refreshNotifications,
                      color: primaryColor,
                      child: _notifications.isEmpty
                          ? ListView(
                              physics: AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.5,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Ionicons.notifications_off_outline,
                                          size: 64,
                                          color: subtleTextColor,
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          'No notifications yet',
                                          style: GoogleFonts.inter(
                                            fontSize: 16,
                                            color: subtleTextColor,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Pull down to refresh',
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            color: subtleTextColor.withOpacity(
                                              0.7,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              physics: AlwaysScrollableScrollPhysics(),
                              padding: EdgeInsets.all(16),
                              itemCount: _notifications.length,
                              itemBuilder: (context, index) {
                                final notification = _notifications[index];
                                return _buildNotificationCard(
                                  notification,
                                  primaryColor,
                                  textColor,
                                  subtleTextColor,
                                  isDark,
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
    Map<String, dynamic> notification,
    Color primaryColor,
    Color textColor,
    Color subtleTextColor,
    bool isDark,
  ) {
    final id = notification['id'] as String;
    final title = notification['title'] as String;
    final message = notification['message'] as String;
    final type = notification['type'] as String;
    final timestamp = notification['timestamp'] as DateTime;
    final isRead = notification['isRead'] as bool;

    IconData iconData;
    Color iconColor;
    LinearGradient iconGradient;

    switch (type) {
      case 'success':
        iconData = Ionicons.checkmark_circle;
        iconColor = Color(0xFF2ECC71);
        iconGradient = LinearGradient(
          colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        break;
      case 'warning':
        iconData = Ionicons.warning;
        iconColor = Color(0xFFF39C12);
        iconGradient = LinearGradient(
          colors: [Color(0xFFF39C12), Color(0xFFE67E22)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        break;
      case 'reminder':
        iconData = Ionicons.time;
        iconColor = Color(0xFF3498DB);
        iconGradient = LinearGradient(
          colors: [Color(0xFF3498DB), Color(0xFF2980B9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        break;
      case 'announcement':
        iconData = Ionicons.megaphone;
        iconColor = Color(0xFF9B59B6);
        iconGradient = LinearGradient(
          colors: [Color(0xFF9B59B6), Color(0xFF8E44AD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        break;
      default:
        iconData = Ionicons.information_circle;
        iconColor = primaryColor;
        iconGradient = LinearGradient(
          colors: [primaryColor, primaryColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isRead
              ? (isDark
                    ? Colors.grey.shade800.withOpacity(0.3)
                    : Colors.grey.shade200)
              : iconColor.withOpacity(0.3),
          width: isRead ? 1 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: isRead
                ? (isDark
                      ? Colors.black.withOpacity(0.2)
                      : Colors.black.withOpacity(0.04))
                : iconColor.withOpacity(isDark ? 0.15 : 0.1),
            blurRadius: isRead ? 8 : 12,
            offset: Offset(0, isRead ? 2 : 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (!isRead) {
              _markAsRead(id);
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Beautiful gradient icon with glow effect
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: iconGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: iconColor.withOpacity(0.4),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Icon(iconData, color: Colors.white, size: 28),
                ),
                SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    primaryColor,
                                    primaryColor.withOpacity(0.7),
                                  ],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        message,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: subtleTextColor,
                          height: 1.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      SizedBox(height: 12),
                      // Timestamp with icon
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey.shade800.withOpacity(0.3)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Ionicons.time_outline,
                              size: 14,
                              color: subtleTextColor.withOpacity(0.8),
                            ),
                            SizedBox(width: 6),
                            Text(
                              _formatTimestamp(timestamp),
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: subtleTextColor.withOpacity(0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else {
      return DateFormat('MMM d, yyyy').format(timestamp);
    }
  }
}
