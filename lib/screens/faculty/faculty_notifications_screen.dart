// Faculty Notifications Screen - View notifications and send to students
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ionicons/ionicons.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:attendance_tracking/providers/settings_provider.dart';
import 'package:attendance_tracking/config/api_config.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';

class FacultyNotificationsScreen extends StatefulWidget {
  final String? department;
  final String? profileId;
  final String? facultyName;

  const FacultyNotificationsScreen({
    super.key,
    this.department,
    this.profileId,
    this.facultyName,
  });

  @override
  State<FacultyNotificationsScreen> createState() =>
      _FacultyNotificationsScreenState();
}

class _FacultyNotificationsScreenState extends State<FacultyNotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> _students = [];
  List<String> _selectedStudentIds = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _selectAll = false;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadNotifications();
    _loadStudents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);

    try {
      final url =
          '${ApiConfig.baseUrl}/api/faculty/${widget.profileId}/sent-notifications/';

      final response = await http
          .get(Uri.parse(url), headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _notifications = data.map((e) => e as Map<String, dynamic>).toList();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading notifications: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStudents() async {
    try {
      final url = widget.profileId != null
          ? '${ApiConfig.baseUrl}/api/faculty/${widget.profileId}/students/'
          : '${ApiConfig.baseUrl}/api/faculty/department-students/?department=${widget.department ?? ''}';

      final response = await http
          .get(Uri.parse(url), headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _students = data.map((e) => e as Map<String, dynamic>).toList();
        });
      }
    } catch (e) {
      print('Error loading students: $e');
    }
  }

  void _toggleSelectAll() {
    setState(() {
      _selectAll = !_selectAll;
      if (_selectAll) {
        _selectedStudentIds = _students.map((s) => s['id'].toString()).toList();
      } else {
        _selectedStudentIds.clear();
      }
    });
  }

  void _toggleStudent(String studentId) {
    setState(() {
      if (_selectedStudentIds.contains(studentId)) {
        _selectedStudentIds.remove(studentId);
        _selectAll = false;
      } else {
        _selectedStudentIds.add(studentId);
        if (_selectedStudentIds.length == _students.length) {
          _selectAll = true;
        }
      }
    });
  }

  Future<void> _sendNotification() async {
    if (_titleController.text.trim().isEmpty) {
      Fluttertoast.showToast(
        msg: 'Please enter a notification title',
        backgroundColor: Colors.orange,
      );
      return;
    }

    if (_messageController.text.trim().isEmpty) {
      Fluttertoast.showToast(
        msg: 'Please enter a notification message',
        backgroundColor: Colors.orange,
      );
      return;
    }

    if (_selectedStudentIds.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Please select at least one student',
        backgroundColor: Colors.orange,
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final url = '${ApiConfig.baseUrl}/api/faculty/send-notification/';

      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'faculty_id': widget.profileId,
              'title': _titleController.text.trim(),
              'message': _messageController.text.trim(),
              'student_ids': _selectedStudentIds,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        Fluttertoast.showToast(
          msg: 'Notification sent successfully!',
          backgroundColor: Colors.green,
        );
        _titleController.clear();
        _messageController.clear();
        setState(() {
          _selectedStudentIds.clear();
          _selectAll = false;
        });
        _loadNotifications();
        _tabController.animateTo(0); // Switch to history tab
      } else {
        final error = json.decode(response.body);
        Fluttertoast.showToast(
          msg: error['error'] ?? 'Failed to send notification',
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      print('Error sending notification: $e');
      Fluttertoast.showToast(
        msg: 'Error sending notification',
        backgroundColor: Colors.red,
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Use purple theme for faculty
    const MaterialColor primaryColor = Colors.purple;
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Modern Tab Bar
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
              width: 1,
            ),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.white,
            unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
            labelStyle: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            unselectedLabelStyle: GoogleFonts.inter(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
            labelPadding: EdgeInsets.zero,
            tabs: [
              Tab(
                height: 44,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Ionicons.time_outline, size: 18),
                    const SizedBox(width: 8),
                    const Text('Sent History'),
                  ],
                ),
              ),
              Tab(
                height: 44,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Ionicons.paper_plane_outline, size: 18),
                    const SizedBox(width: 8),
                    const Text('Send New'),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Tab Views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Sent History Tab
              _buildSentHistoryTab(primaryColor, isDark),
              // Send New Tab
              _buildSendNewTab(primaryColor, isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSentHistoryTab(Color primaryColor, bool isDark) {
    if (_isLoading) {
      return Center(
        child: SpinKitFadingCircle(color: primaryColor, size: 50.0),
      );
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Ionicons.notifications_off_outline,
              size: 64,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications sent yet',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _tabController.animateTo(1),
              icon: Icon(Ionicons.add_circle_outline, color: primaryColor),
              label: Text(
                'Send your first notification',
                style: GoogleFonts.inter(color: primaryColor),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      color: primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return _buildNotificationCard(notification, primaryColor, isDark);
        },
      ),
    );
  }

  Widget _buildNotificationCard(
    Map<String, dynamic> notification,
    Color primaryColor,
    bool isDark,
  ) {
    final createdAt = notification['created_at'] != null
        ? DateTime.tryParse(notification['created_at'])
        : null;
    final formattedDate = createdAt != null
        ? DateFormat('MMM dd, yyyy • hh:mm a').format(createdAt)
        : 'Unknown date';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Ionicons.notifications, color: primaryColor),
        ),
        title: Text(
          notification['title'] ?? 'No Title',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              formattedDate,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Ionicons.people_outline,
                  size: 14,
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  '${notification['recipients_count'] ?? 0} recipients',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              notification['message'] ?? 'No message',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[700],
              ),
            ),
          ),
          if (notification['recipients'] != null &&
              (notification['recipients'] as List).isNotEmpty) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (notification['recipients'] as List).map((recipient) {
                  return Chip(
                    avatar: const CircleAvatar(
                      child: Icon(Ionicons.person, size: 14),
                    ),
                    label: Text(
                      recipient['name'] ?? 'Unknown',
                      style: GoogleFonts.inter(fontSize: 12),
                    ),
                    backgroundColor: isDark
                        ? Colors.grey[800]
                        : Colors.grey[100],
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSendNewTab(Color primaryColor, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Field
          Text(
            'Notification Title',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: 'Enter notification title...',
              hintStyle: GoogleFonts.inter(
                color: isDark ? Colors.grey[500] : Colors.grey[400],
              ),
              filled: true,
              fillColor: isDark ? Colors.grey[850] : Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
            style: GoogleFonts.inter(
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 20),

          // Message Field
          Text(
            'Message',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _messageController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Enter your message...',
              hintStyle: GoogleFonts.inter(
                color: isDark ? Colors.grey[500] : Colors.grey[400],
              ),
              filled: true,
              fillColor: isDark ? Colors.grey[850] : Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
            style: GoogleFonts.inter(
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 24),

          // Select Students Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select Students',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[400] : Colors.grey[700],
                ),
              ),
              Row(
                children: [
                  Text(
                    '${_selectedStudentIds.length} selected',
                    style: GoogleFonts.inter(fontSize: 13, color: primaryColor),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: _toggleSelectAll,
                    child: Text(
                      _selectAll ? 'Deselect All' : 'Select All',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Students List
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: _students.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No students found in your department',
                        style: GoogleFonts.inter(
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _students.length,
                    itemBuilder: (context, index) {
                      final student = _students[index];
                      final studentId = student['id'].toString();
                      final isSelected = _selectedStudentIds.contains(
                        studentId,
                      );

                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (_) => _toggleStudent(studentId),
                        activeColor: primaryColor,
                        title: Text(
                          '${student['first_name'] ?? ''} ${student['last_name'] ?? ''}'
                              .trim(),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        subtitle: Text(
                          student['roll_number'] ?? student['email'] ?? '',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isDark ? Colors.grey[500] : Colors.grey[600],
                          ),
                        ),
                        secondary: CircleAvatar(
                          radius: 18,
                          backgroundColor: isDark
                              ? Colors.grey[800]
                              : Colors.grey[300],
                          backgroundImage:
                              student['profile_pic'] != null &&
                                  student['profile_pic'].toString().isNotEmpty
                              ? NetworkImage(student['profile_pic'])
                              : null,
                          child:
                              student['profile_pic'] == null ||
                                  student['profile_pic'].toString().isEmpty
                              ? Icon(
                                  Ionicons.person,
                                  size: 18,
                                  color: isDark
                                      ? Colors.grey[500]
                                      : Colors.grey[500],
                                )
                              : null,
                        ),
                        dense: true,
                        controlAffinity: ListTileControlAffinity.trailing,
                      );
                    },
                  ),
          ),
          const SizedBox(height: 24),

          // Send Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSending ? null : _sendNotification,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: primaryColor.withOpacity(0.5),
              ),
              child: _isSending
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Ionicons.send, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'Send Notification',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
