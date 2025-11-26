import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import services for SystemUiOverlayStyle
import 'package:google_fonts/google_fonts.dart';
import 'package:ionicons/ionicons.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:attendance_tracking/screens/login_page.dart';
import 'package:provider/provider.dart';
import 'package:attendance_tracking/providers/settings_provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart'; // Import SpinKit for loading
import 'dart:convert'; // For potential JSON decoding if fetching data
import 'package:http/http.dart' as http; // For fetching data
import 'dart:ui'; // For ImageFilter
import 'package:fluttertoast/fluttertoast.dart'; // Import fluttertoast
import 'package:intl/intl.dart'; // Import intl package for date formatting

// Import the new settings screen
import 'settings_screen.dart';
// Import the new AttendanceLogsView implementation
import 'attendance_logs_view.dart';
// Import the new NotificationsView implementation
import 'notifications_view.dart';
// Import ApiConfig for API calls
import 'package:attendance_tracking/config/api_config.dart';

// --- New UserDashboardView Implementation (Inspired by Admin Dashboard) ---
class UserDashboardView extends StatefulWidget {
  final String? userName;
  final String? userEmail;
  final String? userId; // Add userId prop

  const UserDashboardView({
    super.key,
    this.userName,
    this.userEmail,
    this.userId, // Add userId to constructor
  });

  @override
  State<UserDashboardView> createState() => _UserDashboardViewState();
}

class _UserDashboardViewState extends State<UserDashboardView> {
  Future<List<Map<String, dynamic>>>? _userStatsFuture;
  Future<List<Map<String, dynamic>>>?
  _userPostedJobsFuture; // Changed from recommended jobs

  // Profile data
  String? _profilePicUrl;
  String? _displayName;
  bool _isProfileLoading = true;

  @override
  void initState() {
    super.initState();
    // Assign futures in initState
    _fetchUserProfile();
    _userStatsFuture = _fetchUserStats();
    _userPostedJobsFuture =
        _fetchUserPostedJobs(); // Changed from recommended jobs
  }

  Future<void> _fetchUserProfile() async {
    if (widget.userId == null) {
      setState(() {
        _isProfileLoading = false;
      });
      return;
    }

    try {
      print('Fetching profile for user: ${widget.userId}');
      final response = await http
          .get(
            Uri.parse(
              '${ApiConfig.baseUrl}/api/student-profile/${widget.userId}/',
            ),
            headers: {'Accept': 'application/json'},
          )
          .timeout(Duration(seconds: 10));

      print('Profile API Response Status: ${response.statusCode}');
      print('Profile API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> profileData = json.decode(response.body);
        setState(() {
          _profilePicUrl = profileData['profilePicUrl'];
          _displayName = profileData['fullName'] ?? widget.userName;
          _isProfileLoading = false;
        });
      } else {
        setState(() {
          _isProfileLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching profile: $e');
      setState(() {
        _isProfileLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchUserStats() async {
    if (widget.userId == null) {
      print('User ID is null, returning default stats');
      return _getDefaultStats();
    }

    try {
      print('Fetching stats for student: ${widget.userId}');
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/student-stats/${widget.userId}/'),
        headers: {'Accept': 'application/json'},
      );

      print('Stats API Response Status: ${response.statusCode}');
      print('Stats API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> statsData = json.decode(response.body);

        // Extract values from API response
        final int presentDays = statsData['present_days'] ?? 0;
        final int absentDays = statsData['absent_days'] ?? 0;
        final int totalClasses = statsData['total_classes'] ?? 0;
        final String attendanceRate =
            statsData['attendance_rate']?.toString() ?? '0%';
        final int weeklyPresent = statsData['weekly_present'] ?? 0;
        final int weeklyAbsent = statsData['weekly_absent'] ?? 0;
        final int weeklyClasses = statsData['weekly_classes'] ?? 0;

        return [
          {
            'title': 'Present Days',
            'count': presentDays.toString(),
            'icon': Ionicons.checkmark_circle_outline,
            'color': '#2ECC71',
            'weeklyValue': weeklyPresent.toString(),
          },
          {
            'title': 'Absent Days',
            'count': absentDays.toString(),
            'icon': Ionicons.close_circle_outline,
            'color': '#E74C3C',
            'weeklyValue': weeklyAbsent.toString(),
          },
          {
            'title': 'Total Classes',
            'count': totalClasses.toString(),
            'icon': Ionicons.calendar_outline,
            'color': '#4A6FE6',
            'weeklyValue': weeklyClasses.toString(),
          },
          {
            'title': 'Attendance Rate',
            'count': attendanceRate,
            'icon': Ionicons.trending_up_outline,
            'color': '#9B59B6',
            'weeklyValue': '75%',
          },
        ];
      } else {
        print('Failed to fetch stats: ${response.statusCode}');
        return _getDefaultStats();
      }
    } catch (e) {
      print('Error fetching user stats: $e');
      return _getDefaultStats();
    }
  }

  Future<List<Map<String, dynamic>>> _fetchUserPostedJobs() async {
    if (widget.userId == null) {
      print('User ID is null, returning empty list');
      return [];
    }

    try {
      print('Fetching jobs posted by user: ${widget.userId}');
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/jobs/user-posted/${widget.userId}/',
        ),
        headers: {'Accept': 'application/json'},
      );

      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> jobsData = json.decode(response.body);
        final List<Map<String, dynamic>> jobs = jobsData.map((job) {
          return {
            'id': job['id']?.toString() ?? '',
            'icon': Ionicons.briefcase_outline,
            'iconBgColor': Color(
              int.parse(
                job['iconBgColor']!.toString().replaceFirst('#', 'FF'),
                radix: 16,
              ),
            ),
            'title': job['title']?.toString() ?? 'No Title',
            'secondary': job['secondary']?.toString() ?? 'No Details',
            'tertiary': job['tertiary']?.toString() ?? 'No Status',
            'status': job['status']?.toString() ?? 'Pending',
            'job_type': job['job_type']?.toString() ?? 'Unknown',
            'description': job['description']?.toString() ?? 'No Description',
            'address': job['address']?.toString() ?? 'No Address',
          };
        }).toList();

        print('Successfully parsed ${jobs.length} jobs');
        return jobs;
      } else {
        print('Failed to fetch jobs: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching user posted jobs: $e');
      return [];
    }
  }

  Future<void> _handleRefresh() async {
    if (mounted) {
      setState(() {
        _isProfileLoading = true;
        // Re-assign futures on refresh
        _userStatsFuture = _fetchUserStats();
        _userPostedJobsFuture =
            _fetchUserPostedJobs(); // Changed from recommended jobs
      });
      // Fetch profile and stats
      await _fetchUserProfile();
      // Await nullable futures safely
      await Future.wait([
        if (_userStatsFuture != null) _userStatsFuture!,
        if (_userPostedJobsFuture != null) _userPostedJobsFuture!,
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final Color primaryColor = settingsProvider.primaryColor;
    final bool isDark = theme.brightness == Brightness.dark;
    final Color textColor =
        theme.textTheme.bodyLarge?.color ??
        (isDark ? Colors.white : Colors.black87);
    final Color subtleTextColor =
        theme.textTheme.bodySmall?.color ??
        (isDark ? Colors.grey.shade400 : Colors.grey.shade600);

    // Use the profile picture from API, fallback to null (will show default)
    final String? profilePicUrl = _profilePicUrl;

    // Use the actual user name from API or widget props, fallback to 'User' if null
    final String displayName = _displayName ?? widget.userName ?? 'User';

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeHeader(
              context,
              displayName,
              profilePicUrl,
              textColor,
              subtleTextColor,
              primaryColor,
            ),
            const SizedBox(height: 30),
            _buildStatsSection(context),
            const SizedBox(height: 24),
            // Removed _buildQuickActions line
            _buildUserPostedJobsList(
              context,
              primaryColor,
              isDark,
            ), // Changed from recommended jobs
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(
    BuildContext context,
    String name,
    String? profilePicUrl,
    Color textColor,
    Color subtleTextColor,
    Color primaryColor,
  ) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    // Define the default image URL
    const String defaultProfilePicUrl =
        'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?q=80&w=1974&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D';

    // Get current date and time
    final now = DateTime.now();
    // Format date and time (e.g., "EEEE, MMM d • h:mm a")
    final String formattedDateTime = DateFormat(
      'EEEE, MMM d • h:mm a',
    ).format(now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Profile and Welcome Text Row
        Row(
          children: [
            // Profile Avatar with gradient border
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    primaryColor.withOpacity(0.7),
                    primaryColor.withOpacity(0.3),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.15),
                    blurRadius: 8,
                    spreadRadius: 2,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(2), // Border width
              child: CircleAvatar(
                radius: 28,
                backgroundColor: isDark ? Colors.grey[800] : Colors.white,
                // Use ClipRRect to ensure the image is clipped to the circle
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Image.network(
                    profilePicUrl ??
                        defaultProfilePicUrl, // Use default if null
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    // Add error builder for network image
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback to initials if the default image also fails
                      final initials = name.isNotEmpty
                          ? name[0].toUpperCase()
                          : '?';
                      return Center(
                        child: Text(
                          initials,
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                      );
                    },
                    // Optional: Add loading builder
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Welcome Text Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome Back,',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: subtleTextColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    name,
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6), // Add spacing before date/time
                  // Display formatted date and time
                  Text(
                    formattedDateTime,
                    style: GoogleFonts.outfit(
                      color: subtleTextColor.withOpacity(0.8), // Slightly faded
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            // Notification Icon with Badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: Icon(
                    Ionicons.notifications_outline,
                    color: subtleTextColor,
                    size: 24,
                  ),
                  onPressed: () {},
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.scaffoldBackgroundColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    // Handle null future in FutureBuilder
    if (_userStatsFuture == null) {
      // Show loading or placeholder if future is null initially
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 30.0),
          child: SpinKitFadingCircle(color: Colors.grey, size: 30.0),
        ),
      );
    }
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _userStatsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 30.0),
              child: SpinKitFadingCircle(color: Colors.grey, size: 30.0),
            ),
          );
        } else if (snapshot.hasError) {
          return Center(child: Text('Error loading stats: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No stats available.'));
        }

        final stats = snapshot.data!;
        // Replace GridView with horizontal ListView
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text(
                'App Stats',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 150, // Increased height for the scrolling container
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: stats.length,
                itemBuilder: (context, index) {
                  final stat = stats[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      right: 16.0,
                      left: index == 0 ? 0 : 0,
                    ),
                    child: _buildStatCard(
                      context: context,
                      title: stat['title'] as String,
                      count: stat['count'] as String,
                      icon: stat['icon'] as IconData,
                      color: _colorFromHex(stat['color'] as String),
                      weeklyValue: stat['weeklyValue'] as String,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // --- Google Earth Style Stat Card Widget with dark mode support ---
  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required String count,
    required IconData icon,
    required Color color, // Primary accent color
    String weeklyValue = '0',
  }) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    // Theme-aware colors
    final Color cardBgColor = isDark ? Color(0xFF131313) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color labelColor = isDark
        ? Colors.white.withOpacity(0.6)
        : Colors.black.withOpacity(0.5);
    final Color starColor = Colors.amber;

    // Increase width and height for better visibility in horizontal layout
    final double cardWidth = 240.0;
    final double cardHeight = 200.0;

    // Clean up weeklyValue (remove '+' prefix if present)
    String cleanWeeklyValue = weeklyValue
        .replaceAll('+', '')
        .replaceAll('-', '');

    // Define relevant stats based on the card title
    String leftLabel = '';
    String leftValue = '';
    String rightLabel = '';
    String rightValue = '';

    switch (title) {
      case 'Present Days':
        leftLabel = 'This Week';
        leftValue = cleanWeeklyValue;
        rightLabel = 'This Month';
        rightValue = count;
        break;
      case 'Absent Days':
        leftLabel = 'This Week';
        leftValue = cleanWeeklyValue == '--' ? '0' : cleanWeeklyValue;
        rightLabel = 'This Month';
        rightValue = count;
        break;
      case 'Total Classes':
        leftLabel = 'This Week';
        leftValue = cleanWeeklyValue;
        rightLabel = 'This Month';
        rightValue = count;
        break;
      case 'Attendance Rate':
        leftLabel = 'Target';
        leftValue = '75%';
        rightLabel = 'Current';
        rightValue = count;
        break;
      default:
        leftLabel = 'Current';
        leftValue = count;
        rightLabel = 'Total';
        rightValue = count;
    }

    return Container(
      width: cardWidth,
      height: cardHeight,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Top-Left Corner Circle
          Positioned(
            left: -20,
            top: -20,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.7), color],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          // Bottom-Right Corner
          Positioned(
            right: -25,
            bottom: -25,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.8), color],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          // Top-Right Small Live Tag
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.green.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Text(
                'Live',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Main Card Content
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Dashboard Label
                Text(
                  'Dashboard',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: labelColor,
                  ),
                ),

                // Title
                Padding(
                  padding: const EdgeInsets.only(top: 6.0, bottom: 6.0),
                  child: Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Count with star rating
                Row(
                  children: [
                    Icon(Ionicons.star, color: starColor, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      count,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Bottom Stats - Two relevant metrics using actual data
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left metric
                    Row(
                      children: [
                        Text(
                          leftLabel,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: labelColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          leftValue,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),

                    // Right metric
                    Row(
                      children: [
                        Text(
                          rightLabel,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: labelColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          rightValue,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserPostedJobsList(
    BuildContext context,
    Color primaryColor,
    bool isDark,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: theme.textTheme.bodyLarge?.color,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        _buildRecentActivityListFromAPI(theme, isDark),
      ],
    );
  }

  Widget _buildRecentActivityListFromAPI(ThemeData theme, bool isDark) {
    if (widget.userId == null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Text(
            'No recent activity',
            style: GoogleFonts.outfit(color: theme.textTheme.bodySmall?.color),
          ),
        ),
      );
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchRecentActivity(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 30.0),
              child: SpinKitFadingCircle(color: Colors.grey, size: 30.0),
            ),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'Error loading activity',
                style: GoogleFonts.outfit(color: Colors.red),
              ),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  Icon(
                    Ionicons.calendar_outline,
                    size: 48,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No recent activity',
                    style: GoogleFonts.outfit(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final activities = snapshot.data!;
        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: activities.length,
          itemBuilder: (context, index) {
            final activity = activities[index];
            return _buildActivityCard(activity, theme, isDark);
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchRecentActivity() async {
    if (widget.userId == null) return _getDefaultRecentActivity();

    try {
      print('Fetching recent activity for student: ${widget.userId}');
      final response = await http
          .get(
            Uri.parse(
              '${ApiConfig.baseUrl}/api/student-activity/${widget.userId}/',
            ),
            headers: {'Accept': 'application/json'},
          )
          .timeout(Duration(seconds: 5));

      print('Activity API Response Status: ${response.statusCode}');
      print('Activity API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> activityData = json.decode(response.body);

        return activityData.map((activity) {
          // Map icon names from backend to Ionicons
          IconData iconData;
          switch (activity['icon']) {
            case 'checkmark_circle':
              iconData = Ionicons.checkmark_circle;
              break;
            case 'log_out':
              iconData = Ionicons.log_out;
              break;
            case 'time':
              iconData = Ionicons.time;
              break;
            default:
              iconData = Ionicons.information_circle;
          }

          return {
            'title': activity['title'] ?? '',
            'description': activity['description'] ?? '',
            'time': activity['time'] ?? '',
            'icon': iconData,
            'iconColor': activity['iconColor'] ?? '#4A6FE6',
            'type': activity['type'] ?? 'info',
          };
        }).toList();
      } else {
        print(
          'Failed to fetch recent activity: ${response.statusCode}, using default',
        );
        return _getDefaultRecentActivity();
      }
    } catch (e) {
      print('Error fetching recent activity: $e');
      return _getDefaultRecentActivity();
    }
  }

  List<Map<String, dynamic>> _getDefaultRecentActivity() {
    return [
      {
        'title': 'Attendance Marked',
        'description': 'Computer Science',
        'time': '2 hours ago',
        'icon': Ionicons.checkmark_circle,
        'iconColor': '#2ECC71',
        'type': 'success',
      },
      {
        'title': 'Class Reminder',
        'description': 'Mathematics starts in 30 minutes',
        'time': '5 hours ago',
        'icon': Ionicons.time,
        'iconColor': '#3498DB',
        'type': 'reminder',
      },
      {
        'title': 'Face Recognition Update',
        'description': 'Profile updated successfully',
        'time': '1 day ago',
        'icon': Ionicons.person_circle,
        'iconColor': '#9B59B6',
        'type': 'info',
      },
      {
        'title': 'Attendance Report',
        'description': 'Weekly report generated',
        'time': '2 days ago',
        'icon': Ionicons.document_text,
        'iconColor': '#F39C12',
        'type': 'report',
      },
    ];
  }

  Widget _buildActivityCard(
    Map<String, dynamic> activity,
    ThemeData theme,
    bool isDark,
  ) {
    final String title = activity['title'] ?? '';
    final String description = activity['description'] ?? '';
    final String time = activity['time'] ?? '';
    final IconData icon = activity['icon'] ?? Ionicons.information_circle;
    final String iconColorHex = activity['iconColor'] ?? '#4A6FE6';
    final Color iconColor = Color(
      int.parse(iconColorHex.replaceFirst('#', '0xFF')),
    );

    final cardColor = isDark ? Color.fromARGB(255, 16, 16, 16) : Colors.white;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final subtitleColor = theme.textTheme.bodySmall?.color ?? Colors.grey;
    final borderColor = isDark
        ? const Color.fromARGB(255, 89, 89, 89).withOpacity(0.5)
        : Colors.grey.shade200;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.15)
                : Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon container with gradient
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [iconColor.withOpacity(0.8), iconColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: iconColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: subtitleColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Time
            Text(
              time,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: subtitleColor.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to convert string to IconData
  IconData _getIconFromString(String iconString) {
    switch (iconString) {
      case 'briefcase_outline':
        return Ionicons.briefcase_outline;
      case 'checkmark_circle_outline':
        return Ionicons.checkmark_circle_outline;
      case 'business_outline':
        return Ionicons.business_outline;
      case 'people_outline':
        return Ionicons.people_outline;
      case 'bookmark_outline':
        return Ionicons.bookmark_outline;
      case 'eye_outline':
        return Ionicons.eye_outline;
      case 'chatbubbles_outline':
        return Ionicons.chatbubbles_outline;
      // Add the icon mappings that match the backend response
      case 'briefcase':
        return Ionicons.briefcase_outline;
      case 'checkmark_circle':
        return Ionicons.checkmark_circle_outline;
      case 'business':
        return Ionicons.business_outline;
      case 'people':
        return Ionicons.people_outline;
      default:
        return Ionicons.briefcase_outline;
    }
  }

  Color _colorFromHex(String hexString) {
    hexString = hexString.replaceFirst('#', '');
    if (hexString.length == 6) {
      hexString = 'FF' + hexString;
    }
    try {
      return Color(int.parse(hexString, radix: 16));
    } catch (e) {
      print("Error parsing color: $hexString, Error: $e");
      return Colors.grey;
    }
  }

  List<Map<String, dynamic>> _getDefaultStats() {
    return [
      {
        'title': 'Present Days',
        'count': '0',
        'icon': Ionicons.checkmark_circle_outline,
        'color': '#2ECC71',
        'weeklyValue': '0',
      },
      {
        'title': 'Absent Days',
        'count': '0',
        'icon': Ionicons.close_circle_outline,
        'color': '#E74C3C',
        'weeklyValue': '0',
      },
      {
        'title': 'Total Classes',
        'count': '0',
        'icon': Ionicons.calendar_outline,
        'color': '#4A6FE6',
        'weeklyValue': '0',
      },
      {
        'title': 'Attendance Rate',
        'count': '0%',
        'icon': Ionicons.trending_up_outline,
        'color': '#9B59B6',
        'weeklyValue': '75%',
      },
    ];
  }
}
// --- End UserDashboardView Implementation ---

class UserDashboard extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String userId;

  const UserDashboard({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.userId,
  });

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  int _selectedIndex = 0;

  final _storage = const FlutterSecureStorage();
  static const String _storageEmailKey = 'saved_email';

  String? _userName;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _loadUserDataForDrawer();
  }

  Future<void> _loadUserDataForDrawer() async {
    final email = await _storage.read(key: _storageEmailKey);
    if (mounted) {
      setState(() {
        _userEmail = email;
        // Use the userName passed from login instead of deriving from email
        _userName = widget.userName;
        // Only fallback to email-derived name if userName is not provided
        if (_userName == null && _userEmail != null) {
          _userName = _userEmail!.split('@').first;
          _userName = _userName![0].toUpperCase() + _userName!.substring(1);
        }
      });
    }
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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
      }
    }
  }

  // Method to show worker feedback dialog
  Future<void> _showWorkerFeedbackDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _WorkerListDialog(userId: widget.userId);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final MaterialColor primaryMaterialColor = settingsProvider.primaryColor;
    final Color primaryColor = primaryMaterialColor;
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final List<Widget> screens = [
      UserDashboardView(
        userName: widget.userName,
        userEmail: widget.userEmail,
        userId: widget.userId,
      ),
      AttendanceLogsView(userId: widget.userId),
      NotificationsView(userId: widget.userId),
      UserSettingsScreen(
        userName: widget.userName,
        userEmail: widget.userEmail,
        userId: widget.userId,
      ),
    ];

    final SystemUiOverlayStyle systemUiOverlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      // Adapt status bar icons to theme brightness
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemUiOverlayStyle,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          // Use theme background color instead of hardcoded white
          backgroundColor: isDark
              ? theme.scaffoldBackgroundColor
              : Colors.white,
          // Use theme text color for contrast
          foregroundColor: isDark ? Colors.white : Colors.black87,
          elevation: isDark
              ? 0
              : 0.5, // Less elevation in dark mode for a flat look
          shadowColor: Colors.black.withOpacity(isDark ? 0.0 : 0.05),
          title: Text(
            _getAppBarTitle(_selectedIndex),
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: isDark
                  ? Colors.white
                  : Colors.black87, // Theme-aware text color
            ),
          ),
          centerTitle: true,
          toolbarHeight: 65,
          leading: Builder(
            builder: (context) => IconButton(
              icon: Icon(Ionicons.menu_outline),
              tooltip: 'Menu',
              onPressed: () => Scaffold.of(context).openDrawer(),
              color: isDark
                  ? Colors.white
                  : Colors.black87, // Theme-aware icon color
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Ionicons.log_out_outline),
              tooltip: 'Logout',
              onPressed: () {
                _logout(context);
              },
              color: isDark
                  ? Colors.white
                  : Colors.black87, // Theme-aware icon color
            ),
            const SizedBox(width: 12),
          ],
          // Theme-aware bottom border
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(1.0),
            child: Container(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              height: isDark ? 0.5 : 1.0, // Thinner line in dark mode
            ),
          ),
        ),
        drawer: _buildDrawer(primaryMaterialColor),
        body: IndexedStack(index: _selectedIndex, children: screens),
        bottomNavigationBar: _buildSimpleBottomNavigationBar(
          primaryMaterialColor,
        ),
      ),
    );
  }

  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return 'Attendance Dashboard';
      case 1:
        return 'Attendance Logs';
      case 2:
        return 'Notifications';
      case 3:
        return 'Settings';
      default:
        return 'Dashboard';
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
            height: 180,
            decoration: BoxDecoration(color: headerColor),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 40.0, 16.0, 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withOpacity(0.9),
                    child: Icon(
                      Ionicons.person_outline,
                      size: 30,
                      color: headerColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.userName ?? 'User',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    widget.userEmail ?? 'user@example.com',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
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
            icon: Ionicons.list_outline,
            text: 'Attendance Logs',
            selected: _selectedIndex == 1,
            selectedColor: headerColor,
            defaultIconColor: drawerIconColor,
            defaultTextColor: drawerTextColor,
            onTap: () => _onSelectItem(1),
          ),
          _buildDrawerItem(
            icon: Ionicons.notifications_outline,
            text: 'Notifications',
            selected: _selectedIndex == 2,
            selectedColor: headerColor,
            defaultIconColor: drawerIconColor,
            defaultTextColor: drawerTextColor,
            onTap: () => _onSelectItem(2),
          ),
          Divider(color: theme.dividerColor),
          _buildDrawerItem(
            icon: Ionicons.finger_print_outline,
            text: 'Face Recognition',
            selected: false,
            selectedColor: headerColor,
            defaultIconColor: drawerIconColor,
            defaultTextColor: drawerTextColor,
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to face recognition enrollment
            },
          ),
          _buildDrawerItem(
            icon: Ionicons.settings_outline,
            text: 'Settings',
            selected: _selectedIndex == 3,
            selectedColor: headerColor,
            defaultIconColor: drawerIconColor,
            defaultTextColor: drawerTextColor,
            onTap: () => _onSelectItem(3),
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
              const SizedBox(width: 20),
              Text(
                text,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onSelectItem(int index) {
    Navigator.pop(context);
    if (index >= 0 && index < 4) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Widget _buildSimpleBottomNavigationBar(MaterialColor activeColor) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Color.fromARGB(255, 25, 25, 30) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            width: 0.5,
          ),
        ),
      ),
      height: 70, // Increased height to accommodate labels
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavBarIconButton(
            icon: Ionicons.home_outline,
            activeIcon: Ionicons.home,
            label: 'Home',
            isSelected: _selectedIndex == 0,
            activeColor: activeColor,
            onTap: () => setState(() => _selectedIndex = 0),
          ),
          _buildNavBarIconButton(
            icon: Ionicons.list_outline,
            activeIcon: Ionicons.list,
            label: 'Logs',
            isSelected: _selectedIndex == 1,
            activeColor: activeColor,
            onTap: () => setState(() => _selectedIndex = 1),
          ),
          _buildNavBarIconButton(
            icon: Ionicons.notifications_outline,
            activeIcon: Ionicons.notifications,
            label: 'Notifications',
            isSelected: _selectedIndex == 2,
            activeColor: activeColor,
            onTap: () => setState(() => _selectedIndex = 2),
          ),
          _buildNavBarIconButton(
            icon: Ionicons.settings_outline,
            activeIcon: Ionicons.settings,
            label: 'Settings',
            isSelected: _selectedIndex == 3,
            activeColor: activeColor,
            onTap: () => setState(() => _selectedIndex = 3),
          ),
        ],
      ),
    );
  }

  Widget _buildNavBarIconButton({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color textColor = isSelected
        ? activeColor
        : (isDark ? Colors.grey.shade500 : Colors.grey.shade600);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isSelected ? activeIcon : icon, color: textColor, size: 24),
            const SizedBox(height: 4),
            // Add the label text
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                color: textColor,
              ),
            ),
            // Only show indicator dot for selected item if we have labels
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 3),
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: activeColor,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// --- Feedback Form Dialog Widget ---
class _FeedbackFormDialog extends StatefulWidget {
  final String? userId;
  final Map<String, dynamic>? worker;

  const _FeedbackFormDialog({Key? key, this.userId, this.worker})
    : super(key: key);

  @override
  __FeedbackFormDialogState createState() => __FeedbackFormDialogState();
}

class __FeedbackFormDialogState extends State<_FeedbackFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _feedbackController = TextEditingController();

  int _rating = 5;
  int _workQuality = 5;
  int _punctuality = 5;
  int _communication = 5;
  int _professionalism = 5;
  bool _wouldHireAgain = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate() || widget.worker == null) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/feedback/submit/'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'job_id': widget.worker!['job_id'],
          'worker_id': widget.worker!['id'],
          'user_id': widget.userId,
          'rating': _rating,
          'feedback_text': _feedbackController.text.trim(),
          'work_quality': _workQuality,
          'punctuality': _punctuality,
          'communication': _communication,
          'professionalism': _professionalism,
          'would_hire_again': _wouldHireAgain,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        Fluttertoast.showToast(
          msg: 'Feedback submitted successfully!',
          backgroundColor: Colors.green,
          textColor: Colors.white,
          toastLength: Toast.LENGTH_LONG,
        );
        Navigator.of(context).pop();
      } else {
        final data = json.decode(response.body);
        Fluttertoast.showToast(
          msg: data['error'] ?? 'Failed to submit feedback',
          backgroundColor: Colors.red,
          textColor: Colors.white,
          toastLength: Toast.LENGTH_LONG,
        );
      }
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Error: $e',
          backgroundColor: Colors.red,
          textColor: Colors.white,
          toastLength: Toast.LENGTH_LONG,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final Color primaryColor = settingsProvider.primaryColor;

    if (widget.worker == null) {
      return Dialog(
        child: Container(
          padding: EdgeInsets.all(20),
          child: Text('No worker data available'),
        ),
      );
    }

    final String workerName = widget.worker!['name'] ?? 'Unknown Worker';
    final String jobTitle = widget.worker!['job_title'] ?? 'Unknown Job';

    return Dialog(
      backgroundColor: isDark ? Color.fromARGB(255, 23, 23, 23) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Ionicons.star_outline, color: primaryColor, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rate Worker',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      Text(
                        '$workerName • $jobTitle',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Ionicons.close_outline,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Form
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Overall Rating
                      _buildRatingSection(
                        'Overall Rating',
                        _rating,
                        (value) => setState(() => _rating = value),
                        isDark,
                        primaryColor,
                      ),
                      SizedBox(height: 20),

                      // Work Quality
                      _buildRatingSection(
                        'Work Quality',
                        _workQuality,
                        (value) => setState(() => _workQuality = value),
                        isDark,
                        primaryColor,
                      ),
                      SizedBox(height: 20),

                      // Punctuality
                      _buildRatingSection(
                        'Punctuality',
                        _punctuality,
                        (value) => setState(() => _punctuality = value),
                        isDark,
                        primaryColor,
                      ),
                      SizedBox(height: 20),

                      // Communication
                      _buildRatingSection(
                        'Communication',
                        _communication,
                        (value) => setState(() => _communication = value),
                        isDark,
                        primaryColor,
                      ),
                      SizedBox(height: 20),

                      // Professionalism
                      _buildRatingSection(
                        'Professionalism',
                        _professionalism,
                        (value) => setState(() => _professionalism = value),
                        isDark,
                        primaryColor,
                      ),
                      SizedBox(height: 20),

                      // Would Hire Again
                      Row(
                        children: [
                          Text(
                            'Would hire again?',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          Spacer(),
                          Switch(
                            value: _wouldHireAgain,
                            onChanged: (value) =>
                                setState(() => _wouldHireAgain = value),
                            activeColor: primaryColor,
                          ),
                        ],
                      ),
                      SizedBox(height: 20),

                      // Comments
                      Text(
                        'Comments',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: _feedbackController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Share your experience with this worker...',
                          hintStyle: GoogleFonts.outfit(
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark
                                  ? Colors.grey.shade600
                                  : Colors.grey.shade300,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: primaryColor,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: isDark
                              ? Color(0xFF2A2A3A)
                              : Colors.grey.shade50,
                        ),
                        style: GoogleFonts.outfit(
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please provide feedback comments';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Actions
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? Colors.grey.shade300
                            : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitFeedback,
                    child: _isSubmitting
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            'Submit',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection(
    String title,
    int currentRating,
    Function(int) onRatingChanged,
    bool isDark,
    Color primaryColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        SizedBox(height: 8),
        Row(
          children: List.generate(5, (index) {
            final rating = index + 1;
            return GestureDetector(
              onTap: () => onRatingChanged(rating),
              child: Container(
                margin: EdgeInsets.only(right: 8),
                child: Icon(
                  rating <= currentRating
                      ? Ionicons.star
                      : Ionicons.star_outline,
                  color: rating <= currentRating ? Colors.amber : Colors.grey,
                  size: 28,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// --- Worker List Dialog Widget ---
class _WorkerListDialog extends StatefulWidget {
  final String userId;

  const _WorkerListDialog({Key? key, required this.userId}) : super(key: key);

  @override
  __WorkerListDialogState createState() => __WorkerListDialogState();
}

class __WorkerListDialogState extends State<_WorkerListDialog> {
  Future<List<Map<String, dynamic>>>? _workersFuture;

  @override
  void initState() {
    super.initState();
    _workersFuture = _fetchAssignedWorkers();
  }

  Future<List<Map<String, dynamic>>> _fetchAssignedWorkers() async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/users/${widget.userId}/assigned-workers/',
        ),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Failed to load assigned workers');
      }
    } catch (e) {
      print('Error fetching assigned workers: $e');
      throw Exception('Failed to load assigned workers');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final Color primaryColor = settingsProvider.primaryColor;

    return Dialog(
      backgroundColor: isDark ? Color.fromARGB(255, 23, 23, 23) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Ionicons.star_outline, color: primaryColor, size: 24),
                SizedBox(width: 12),
                Text(
                  'Rate Workers',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Ionicons.close_outline,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Select a worker to provide feedback',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            SizedBox(height: 20),

            // Workers List
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _workersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: SpinKitFadingCircle(color: primaryColor, size: 40),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Ionicons.alert_circle_outline,
                            size: 48,
                            color: Colors.red,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Error loading workers',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            snapshot.error.toString(),
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  final workers = snapshot.data ?? [];

                  if (workers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Ionicons.people_outline,
                            size: 48,
                            color: isDark ? Colors.white54 : Colors.black38,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No Workers Found',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'No workers have been assigned\nto your posted jobs yet.',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: workers.length,
                    itemBuilder: (context, index) {
                      final worker = workers[index];
                      return _buildWorkerCard(worker, primaryColor, isDark);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkerCard(
    Map<String, dynamic> worker,
    Color primaryColor,
    bool isDark,
  ) {
    final String workerName = worker['name'] ?? 'Unknown Worker';
    final String workerEmail = worker['email'] ?? '';
    final String workerPhone = worker['phone'] ?? '';
    final String jobTitle = worker['job_title'] ?? '';
    final String jobStatus = worker['job_status'] ?? '';
    final String? profilePicUrl = worker['profile_pic_url'];
    final bool hasFeedback = worker['has_feedback'] ?? false;
    final double? existingRating = worker['feedback_rating']?.toDouble();
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: hasFeedback
            ? (isDark ? Color.fromARGB(255, 38, 52, 38) : Colors.green.shade50)
            : (isDark ? Color.fromARGB(255, 30, 30, 30) : Colors.grey.shade50),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasFeedback
              ? (isDark ? Colors.green.shade600 : Colors.green.shade200)
              : (isDark
                    ? Colors.grey.shade700.withOpacity(0.2)
                    : Colors.grey.shade200),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: hasFeedback
            ? () {
                // Show a message that feedback has already been submitted
                Fluttertoast.showToast(
                  msg: 'You have already rated this worker',
                  backgroundColor: Colors.orange,
                  textColor: Colors.white,
                  toastLength: Toast.LENGTH_SHORT,
                );
              }
            : () {
                Navigator.of(context).pop(); // Close worker list dialog
                _showFeedbackForm(context, worker); // Show feedback form
              },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              // Profile Picture
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor.withOpacity(0.1),
                  border: Border.all(
                    color: primaryColor.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: profilePicUrl != null
                    ? ClipOval(
                        child: Image.network(
                          profilePicUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildInitialsAvatar(
                              workerName,
                              primaryColor,
                            );
                          },
                        ),
                      )
                    : _buildInitialsAvatar(workerName, primaryColor),
              ),
              SizedBox(width: 16),

              // Worker Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            workerName,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                        if (hasFeedback && existingRating != null)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.amber.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Ionicons.star,
                                  size: 12,
                                  color: Colors.amber,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  existingRating.toStringAsFixed(1),
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.amber.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 4),
                    if (workerPhone.isNotEmpty)
                      Text(
                        workerPhone,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    SizedBox(height: 2),
                    if (jobTitle.isNotEmpty)
                      Text(
                        'Job: $jobTitle',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: isDark ? Colors.white60 : Colors.black45,
                        ),
                      ),
                    if (jobStatus.isNotEmpty)
                      Text(
                        'Status: $jobStatus',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: _getStatusColor(jobStatus),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ), // Action Indicator
              Column(
                children: [
                  if (hasFeedback)
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Ionicons.checkmark_circle,
                        color: Colors.green,
                        size: 20,
                      ),
                    )
                  else
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: primaryColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Ionicons.star_outline,
                        color: primaryColor,
                        size: 20,
                      ),
                    ),
                  SizedBox(height: 4),
                  Text(
                    hasFeedback ? 'Rated' : 'Rate',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: hasFeedback ? Colors.green : primaryColor,
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

  Widget _buildInitialsAvatar(String name, Color primaryColor) {
    final initials = name
        .split(' ')
        .map((part) => part.isNotEmpty ? part[0].toUpperCase() : '')
        .take(2)
        .join('');

    return Center(
      child: Text(
        initials.isNotEmpty ? initials : 'W',
        style: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: primaryColor,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in progress':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  void _showFeedbackForm(BuildContext context, Map<String, dynamic> worker) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _FeedbackFormDialog(userId: widget.userId, worker: worker);
      },
    );
  }
}
