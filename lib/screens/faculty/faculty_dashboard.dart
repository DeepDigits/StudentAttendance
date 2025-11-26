// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ionicons/ionicons.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:attendance_tracking/screens/login_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:attendance_tracking/providers/settings_provider.dart';
import 'package:attendance_tracking/config/api_config.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

// Import faculty screens
import 'faculty_students_screen.dart';
import 'faculty_attendance_screen.dart';
import 'faculty_notifications_screen.dart';
import 'faculty_settings_screen.dart';

class FacultyDashboard extends StatefulWidget {
  final String? userName;
  final String? userEmail;
  final String? userId;
  final String? profileId;
  final String? department;

  const FacultyDashboard({
    super.key,
    this.userName,
    this.userEmail,
    this.userId,
    this.profileId,
    this.department,
  });

  @override
  State<FacultyDashboard> createState() => _FacultyDashboardState();
}

class _FacultyDashboardState extends State<FacultyDashboard> {
  final _storage = const FlutterSecureStorage();
  int _selectedIndex = 0;

  // Faculty profile data
  String? _profilePicUrl;
  String? _displayName;
  String? _department;
  String? _employeeId;
  bool _isLoading = true;

  // Dashboard stats
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadFacultyProfile();
    _loadDashboardStats();
  }

  Future<void> _loadFacultyProfile() async {
    if (widget.profileId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/api/faculty/${widget.profileId}/'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _displayName = '${data['first_name']} ${data['last_name']}'.trim();
          if (_displayName!.isEmpty) _displayName = widget.userName;
          _profilePicUrl = data['profile_pic_url'];
          _department = data['department'] ?? widget.department;
          _employeeId = data['employee_id'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _displayName = widget.userName;
          _department = widget.department;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading faculty profile: $e');
      setState(() {
        _displayName = widget.userName;
        _department = widget.department;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDashboardStats() async {
    if (widget.profileId == null || widget.profileId!.isEmpty) {
      print('ProfileId is null or empty, skipping stats load');
      return;
    }

    try {
      final url =
          '${ApiConfig.baseUrl}/api/faculty/${widget.profileId}/dashboard-stats/';
      print('Loading dashboard stats from: $url'); // Debug log

      final response = await http
          .get(Uri.parse(url), headers: {'Accept': 'application/json'})
          .timeout(Duration(seconds: 10));

      print('Stats response status: ${response.statusCode}'); // Debug log
      print('Stats response body: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        setState(() {
          _stats = json.decode(response.body);
        });
      } else {
        print('Failed to load stats: ${response.body}');
      }
    } catch (e) {
      print('Error loading dashboard stats: $e');
    }
  }

  Future<void> _handleRefresh() async {
    await _loadFacultyProfile();
    await _loadDashboardStats();
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await _storage.deleteAll();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      print("Error during logout: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    // Use purple theme for faculty dashboard
    const MaterialColor primaryColor = Colors.purple;
    final theme = Theme.of(context);

    final List<Widget> screens = [
      FacultyDashboardView(
        stats: _stats,
        department: _department,
        onRefresh: _handleRefresh,
        profileId: widget.profileId,
      ),
      FacultyStudentsScreen(
        department: _department,
        profileId: widget.profileId,
      ),
      FacultyAttendanceScreen(
        department: _department,
        profileId: widget.profileId,
      ),
      FacultyNotificationsScreen(
        department: _department,
        profileId: widget.profileId,
      ),
      FacultySettingsScreen(profileId: widget.profileId),
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 1.0,
        shadowColor: Colors.black.withOpacity(0.1),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: Text(_getAppBarTitle(_selectedIndex)),
        centerTitle: false,
        toolbarHeight: 70,
        actions: [
          GestureDetector(
            onTap: () => _logout(context),
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0, left: 8.0),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Icon(Icons.logout, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(primaryColor),
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: _buildBottomNavigationBar(primaryColor),
    );
  }

  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return 'Faculty Dashboard';
      case 1:
        return 'My Students';
      case 2:
        return 'Attendance';
      case 3:
        return 'Send Notifications';
      case 4:
        return 'Settings';
      default:
        return 'Faculty Dashboard';
    }
  }

  Widget _buildDrawer(MaterialColor headerColor) {
    final theme = Theme.of(context);
    final drawerTextColor = theme.brightness == Brightness.dark
        ? Colors.grey[300]
        : Colors.grey[800];
    final drawerIconColor = theme.brightness == Brightness.dark
        ? Colors.grey[400]
        : Colors.grey[700];

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          Container(
            color: headerColor,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.white.withOpacity(0.9),
                      backgroundImage: _profilePicUrl != null
                          ? NetworkImage(_profilePicUrl!)
                          : null,
                      child: _profilePicUrl == null
                          ? Icon(
                              Ionicons.person_outline,
                              size: 32,
                              color: headerColor[700],
                            )
                          : null,
                    ),
                    SizedBox(height: 12),
                    Text(
                      _displayName ?? widget.userName ?? 'Faculty',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2),
                    Text(
                      _department ?? 'Department',
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.userEmail != null &&
                        widget.userEmail!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          widget.userEmail!,
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          _buildDrawerItem(
            icon: Ionicons.grid_outline,
            text: 'Dashboard',
            selected: _selectedIndex == 0,
            selectedColor: headerColor,
            defaultIconColor: drawerIconColor!,
            defaultTextColor: drawerTextColor!,
            onTap: () => _onSelectItem(0),
          ),
          _buildDrawerItem(
            icon: Ionicons.people_outline,
            text: 'My Students',
            selected: _selectedIndex == 1,
            selectedColor: headerColor,
            defaultIconColor: drawerIconColor,
            defaultTextColor: drawerTextColor,
            onTap: () => _onSelectItem(1),
          ),
          _buildDrawerItem(
            icon: Ionicons.calendar_outline,
            text: 'Attendance',
            selected: _selectedIndex == 2,
            selectedColor: headerColor,
            defaultIconColor: drawerIconColor,
            defaultTextColor: drawerTextColor,
            onTap: () => _onSelectItem(2),
          ),
          _buildDrawerItem(
            icon: Ionicons.notifications_outline,
            text: 'Send Notifications',
            selected: _selectedIndex == 3,
            selectedColor: headerColor,
            defaultIconColor: drawerIconColor,
            defaultTextColor: drawerTextColor,
            onTap: () => _onSelectItem(3),
          ),
          Divider(color: theme.dividerColor),
          _buildDrawerItem(
            icon: Ionicons.settings_outline,
            text: 'Settings',
            selected: _selectedIndex == 4,
            selectedColor: headerColor,
            defaultIconColor: drawerIconColor,
            defaultTextColor: drawerTextColor,
            onTap: () => _onSelectItem(4),
          ),
          _buildDrawerItem(
            icon: Ionicons.log_out_outline,
            text: 'Logout',
            selected: false,
            selectedColor: headerColor,
            defaultIconColor: drawerIconColor,
            defaultTextColor: drawerTextColor,
            onTap: () {
              Navigator.pop(context);
              _logout(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String text,
    required bool selected,
    required Color selectedColor,
    required Color defaultIconColor,
    required Color defaultTextColor,
    required GestureTapCallback onTap,
  }) {
    final color = selected ? selectedColor : defaultIconColor;
    final textColor = selected ? selectedColor : defaultTextColor;

    return Material(
      color: selected ? selectedColor.withOpacity(0.1) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              SizedBox(width: 16),
              Text(
                text,
                style: GoogleFonts.inter(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onSelectItem(int index) {
    setState(() => _selectedIndex = index);
    Navigator.pop(context);
  }

  Widget _buildBottomNavigationBar(MaterialColor primaryColor) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1E1E1E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                icon: Ionicons.grid_outline,
                activeIcon: Ionicons.grid,
                label: 'Dashboard',
                primaryColor: primaryColor,
                isDark: isDark,
              ),
              _buildNavItem(
                index: 1,
                icon: Ionicons.people_outline,
                activeIcon: Ionicons.people,
                label: 'Students',
                primaryColor: primaryColor,
                isDark: isDark,
              ),
              _buildNavItem(
                index: 2,
                icon: Ionicons.calendar_outline,
                activeIcon: Ionicons.calendar,
                label: 'Attendance',
                primaryColor: primaryColor,
                isDark: isDark,
              ),
              _buildNavItem(
                index: 3,
                icon: Ionicons.notifications_outline,
                activeIcon: Ionicons.notifications,
                label: 'Notify',
                primaryColor: primaryColor,
                isDark: isDark,
              ),
              _buildNavItem(
                index: 4,
                icon: Ionicons.settings_outline,
                activeIcon: Ionicons.settings,
                label: 'Settings',
                primaryColor: primaryColor,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required MaterialColor primaryColor,
    required bool isDark,
  }) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected
                  ? primaryColor
                  : (isDark ? Colors.grey[500] : Colors.grey[600]),
              size: 22,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? primaryColor
                    : (isDark ? Colors.grey[500] : Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Dashboard View Widget
class FacultyDashboardView extends StatelessWidget {
  final Map<String, dynamic> stats;
  final String? department;
  final Future<void> Function() onRefresh;
  final String? profileId;

  const FacultyDashboardView({
    super.key,
    required this.stats,
    this.department,
    required this.onRefresh,
    this.profileId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Use purple theme for faculty
    const MaterialColor primaryColor = Colors.purple;
    final isDark = theme.brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: primaryColor,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            _buildWelcomeCard(context, primaryColor, isDark),
            SizedBox(height: 20),

            // Stats Grid
            _buildStatsSection(context, primaryColor, isDark),
            SizedBox(height: 20),

            // Recent Activity
            _buildRecentActivitySection(context, primaryColor, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(
    BuildContext context,
    Color primaryColor,
    bool isDark,
  ) {
    final today = DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Ionicons.school_outline, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                department ?? 'Department',
                style: GoogleFonts.outfit(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Welcome Back!',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            today,
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.85),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(
    BuildContext context,
    Color primaryColor,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Ionicons.stats_chart, color: primaryColor, size: 20),
            ),
            SizedBox(width: 10),
            Text(
              'Overview',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.grey[800],
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 1.4,
          children: [
            _buildStatCard(
              context,
              icon: Ionicons.people,
              title: 'Total Students',
              value: '${stats['total_students'] ?? 0}',
              color: Colors.blue,
              gradientColors: [Colors.blue.shade400, Colors.blue.shade600],
              isDark: isDark,
            ),
            _buildStatCard(
              context,
              icon: Ionicons.checkmark_circle,
              title: 'Present Today',
              value: '${stats['present_today'] ?? 0}',
              color: Colors.green,
              gradientColors: [Colors.green.shade400, Colors.green.shade600],
              isDark: isDark,
            ),
            _buildStatCard(
              context,
              icon: Ionicons.close_circle,
              title: 'Absent Today',
              value: '${stats['absent_today'] ?? 0}',
              color: Colors.red,
              gradientColors: [Colors.red.shade400, Colors.red.shade600],
              isDark: isDark,
            ),
            _buildStatCard(
              context,
              icon: Ionicons.trending_up,
              title: 'Attendance Rate',
              value: '${stats['attendance_rate'] ?? 0}%',
              color: Colors.purple,
              gradientColors: [Colors.purple.shade400, Colors.purple.shade600],
              isDark: isDark,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required List<Color> gradientColors,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(isDark ? 0.15 : 0.1),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.grey[800],
                ),
              ),
              SizedBox(height: 2),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey[400] : Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitySection(
    BuildContext context,
    Color primaryColor,
    bool isDark,
  ) {
    final recentActivity = stats['recent_activity'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with gradient background
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryColor.withOpacity(0.1),
                primaryColor.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Ionicons.pulse_outline,
                      color: primaryColor,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent Activity',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.grey[800],
                        ),
                      ),
                      Text(
                        'Latest attendance updates',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (recentActivity.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${recentActivity.length}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: 16),

        // Activity List
        recentActivity.isEmpty
            ? Container(
                padding: const EdgeInsets.all(40.0),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900] : Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                  ),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Ionicons.time_outline,
                          size: 48,
                          color: isDark ? Colors.grey[600] : Colors.grey[400],
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'No recent activity',
                        style: GoogleFonts.outfit(
                          color: isDark ? Colors.grey[400] : Colors.grey[700],
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Attendance records will appear here\nwhen students check in',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: isDark ? Colors.grey[600] : Colors.grey[500],
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: recentActivity.length > 10
                    ? 10
                    : recentActivity.length,
                itemBuilder: (context, index) {
                  final activity = recentActivity[index];
                  final action = activity['action']?.toString() ?? '';
                  final isCheckIn = action.toLowerCase().contains('check-in');
                  final isOnTime =
                      action.toLowerCase().contains('on-time') ||
                      action.toLowerCase().contains('on time');
                  final isLate = action.toLowerCase().contains('late');

                  return Container(
                    margin: EdgeInsets.only(bottom: 12),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[900] : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.grey[800]! : Colors.grey[100]!,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Avatar/Icon section
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isCheckIn
                                  ? [
                                      Colors.green.shade400,
                                      Colors.green.shade600,
                                    ]
                                  : [
                                      Colors.orange.shade400,
                                      Colors.orange.shade600,
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    (isCheckIn ? Colors.green : Colors.orange)
                                        .withOpacity(0.3),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            isCheckIn
                                ? Ionicons.enter_outline
                                : Ionicons.exit_outline,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        SizedBox(width: 14),

                        // Info section
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      activity['student_name'] ??
                                          'Unknown Student',
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.grey[800],
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      activity['time'] ?? '',
                                      style: GoogleFonts.inter(
                                        color: primaryColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  // Status badge
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isOnTime
                                          ? Colors.green.withOpacity(0.1)
                                          : isLate
                                          ? Colors.red.withOpacity(0.1)
                                          : Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isOnTime
                                              ? Ionicons.checkmark_circle
                                              : isLate
                                              ? Ionicons.alert_circle
                                              : Ionicons.time,
                                          size: 12,
                                          color: isOnTime
                                              ? Colors.green
                                              : isLate
                                              ? Colors.red
                                              : Colors.orange,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          action,
                                          style: GoogleFonts.inter(
                                            color: isOnTime
                                                ? Colors.green
                                                : isLate
                                                ? Colors.red
                                                : Colors.orange,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  // Roll number
                                  if (activity['roll_number'] != null &&
                                      activity['roll_number']
                                          .toString()
                                          .isNotEmpty)
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.grey[800]
                                            : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        activity['roll_number'],
                                        style: GoogleFonts.inter(
                                          color: isDark
                                              ? Colors.grey[400]
                                              : Colors.grey[600],
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  Spacer(),
                                  // Date
                                  Text(
                                    activity['date'] ?? '',
                                    style: GoogleFonts.inter(
                                      color: isDark
                                          ? Colors.grey[500]
                                          : Colors.grey[400],
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ],
    );
  }
}
