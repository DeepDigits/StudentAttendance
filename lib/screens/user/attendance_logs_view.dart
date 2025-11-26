import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ionicons/ionicons.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:attendance_tracking/config/api_config.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class AttendanceLogsView extends StatefulWidget {
  final String userId;

  const AttendanceLogsView({super.key, required this.userId});

  @override
  State<AttendanceLogsView> createState() => _AttendanceLogsViewState();
}

class _AttendanceLogsViewState extends State<AttendanceLogsView> {
  String _selectedFilter = 'All';
  List<Map<String, dynamic>> _attendanceLogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAttendanceLogs();
  }

  Future<void> _fetchAttendanceLogs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print(widget.userId);
      print('Fetching attendance logs for student: ${widget.userId}');
      final response = await http
          .get(
            Uri.parse(
              '${ApiConfig.baseUrl}/api/student-logs/${widget.userId}/',
            ),
            headers: {'Accept': 'application/json'},
          )
          .timeout(Duration(seconds: 5));

      print('Logs API Response Status: ${response.statusCode}');
      print('Logs API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> logsData = json.decode(response.body);

        setState(() {
          _attendanceLogs = logsData.map((log) {
            return {
              'date': DateTime.parse(log['date']),
              'status': log['status'] ?? 'Absent',
              'checkIn': log['checkIn'] ?? '--',
              'checkOut': log['checkOut'] ?? '--',
              'subject': log['subject'] ?? 'N/A',
              // Do not include faculty/professor names in the UI per user request
              // 'faculty' intentionally omitted
              'confidence': (log['confidence'] ?? 0.0).toDouble(),
            };
          }).toList();
          _isLoading = false;
        });
      } else {
        print(
          'Failed to fetch attendance logs: ${response.statusCode}, using fallback data',
        );
        _useDefaultAttendanceLogs();
      }
    } catch (e) {
      print('Error fetching attendance logs: $e');
      // Use default/fallback data on error
      _useDefaultAttendanceLogs();
    }
  }

  void _useDefaultAttendanceLogs() {
    // Use dummy data as fallback
    final List<Map<String, dynamic>> defaultLogs = [
      {
        'date': DateTime.now().subtract(Duration(days: 0)),
        'status': 'Present',
        'checkIn': '09:05 AM',
        'checkOut': '04:30 PM',
        'subject': 'Mathematics',
        'confidence': 98.5,
      },
      {
        'date': DateTime.now().subtract(Duration(days: 1)),
        'status': 'Present',
        'checkIn': '09:02 AM',
        'checkOut': '04:25 PM',
        'subject': 'Physics',
        'confidence': 96.8,
      },
      {
        'date': DateTime.now().subtract(Duration(days: 2)),
        'status': 'Absent',
        'checkIn': '--',
        'checkOut': '--',
        'subject': 'Chemistry',
        'confidence': 0.0,
      },
      {
        'date': DateTime.now().subtract(Duration(days: 3)),
        'status': 'Present',
        'checkIn': '09:10 AM',
        'checkOut': '04:35 PM',
        'subject': 'Computer Science',
        'confidence': 99.2,
      },
      {
        'date': DateTime.now().subtract(Duration(days: 4)),
        'status': 'Late',
        'checkIn': '09:45 AM',
        'checkOut': '04:30 PM',
        'subject': 'English',
        'confidence': 97.1,
      },
    ];

    setState(() {
      _attendanceLogs = defaultLogs;
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _filteredLogs {
    if (_selectedFilter == 'All') {
      return _attendanceLogs;
    }
    return _attendanceLogs
        .where((log) => log['status'] == _selectedFilter)
        .toList();
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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'Attendance Logs',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Ionicons.refresh, color: textColor),
            onPressed: _fetchAttendanceLogs,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Chips
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All', primaryColor, isDark),
                    SizedBox(width: 8),
                    _buildFilterChip('Present', primaryColor, isDark),
                    SizedBox(width: 8),
                    _buildFilterChip('Absent', primaryColor, isDark),
                    SizedBox(width: 8),
                    _buildFilterChip('Late', primaryColor, isDark),
                  ],
                ),
              ),
            ),
            Divider(
              height: 1,
              color: isDark ? Color(0xFF2A2A2A) : Colors.grey.shade200,
            ),
            // Attendance Logs List
            Expanded(
              child: _isLoading
                  ? Center(
                      child: SpinKitFadingCircle(
                        color: primaryColor,
                        size: 50.0,
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchAttendanceLogs,
                      color: primaryColor,
                      child: _filteredLogs.isEmpty
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
                                          Ionicons.calendar_outline,
                                          size: 64,
                                          color: subtleTextColor,
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          'No attendance logs found',
                                          style: GoogleFonts.inter(
                                            fontSize: 16,
                                            color: subtleTextColor,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Pull down to refresh',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
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
                              itemCount: _filteredLogs.length,
                              itemBuilder: (context, index) {
                                final log = _filteredLogs[index];
                                return _buildAttendanceCard(
                                  log,
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

  Widget _buildFilterChip(String label, Color primaryColor, bool isDark) {
    final isSelected = _selectedFilter == label;
    return FilterChip(
      label: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: isSelected
              ? Colors.white
              : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = label;
        });
      },
      backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
      selectedColor: primaryColor,
      checkmarkColor: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      side: BorderSide(
        color: isSelected
            ? primaryColor
            : (isDark ? Color(0xFF2A2A2A) : Colors.grey.shade300),
        width: 1.5,
      ),
    );
  }

  Widget _buildAttendanceCard(
    Map<String, dynamic> log,
    Color primaryColor,
    Color textColor,
    Color subtleTextColor,
    bool isDark,
  ) {
    final status = log['status'] as String;
    final date = log['date'] as DateTime;
    final checkIn = log['checkIn'] as String;
    final checkOut = log['checkOut'] as String;
    final subject = log['subject'] as String;
    final confidence = log['confidence'] as double;

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'Present':
        statusColor = Colors.green;
        statusIcon = Ionicons.checkmark_circle;
        break;
      case 'Absent':
        statusColor = Colors.red;
        statusIcon = Ionicons.close_circle;
        break;
      case 'Late':
        statusColor = Colors.orange;
        statusIcon = Ionicons.time;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Ionicons.help_circle;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: isDark ? 2 : 1,
      color: isDark ? Color(0xFF131313) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? Color(0xFF2A2A2A) : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 24),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        DateFormat('EEEE, MMM d, yyyy').format(date),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: subtleTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    status,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Divider(
              height: 1,
              color: isDark ? Color(0xFF2A2A2A) : Colors.grey.shade200,
            ),
            SizedBox(height: 12),
            // Details Row
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    Ionicons.enter_outline,
                    'Check In',
                    checkIn,
                    textColor,
                    subtleTextColor,
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    Ionicons.exit_outline,
                    'Check Out',
                    checkOut,
                    textColor,
                    subtleTextColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            // Faculty display removed by user request
            if (confidence > 0) ...[
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Ionicons.finger_print_outline,
                    size: 16,
                    color: primaryColor,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Recognition Confidence: ${confidence.toStringAsFixed(1)}%',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(
    IconData icon,
    String label,
    String value,
    Color textColor,
    Color subtleTextColor,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: subtleTextColor),
        SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 11, color: subtleTextColor),
            ),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
