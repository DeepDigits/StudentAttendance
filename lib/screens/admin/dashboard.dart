// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ionicons/ionicons.dart'; // Import Ionicons
import 'package:fluttertoast/fluttertoast.dart'; // Import fluttertoast
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Import secure storage
import 'package:attendance_tracking/screens/login_page.dart'; // Import Login Page
import 'package:http/http.dart'
    as http; // Add http import if not already present
import 'dart:convert'; // Add for JSON decoding
import 'dart:async'; // Import for Completer
import 'package:intl/intl.dart'; // Import for DateFormat
import 'package:provider/provider.dart'; // Import Provider
import 'package:attendance_tracking/providers/settings_provider.dart'; // Import SettingsProvider

// Import the screen files
import 'faculty_screen.dart'; // Import the faculty screen
import 'students_screen.dart'; // Import the students screen
import 'settings_screen.dart'; // Import the settings screen

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  // Using more relevant stats for the system
  // Keep _statsData here as it might be needed by other parts or could be fetched here
  // final String _baseApiUrl = 'http://10.0.2.2:8000/api';
  final String _baseApiUrl =
      'https://studenttrackingsystem.pythonanywhere.com/api';
  late Future<List<Map<String, dynamic>>> _statsFuture;
  late Future<List<Map<String, dynamic>>> _complaintsFuture; // Add this line

  int _selectedIndex = 0; // For BottomNavigationBar

  // Controllers for Add Worker Dialog
  final _addFirstNameController = TextEditingController();
  final _addLastNameController = TextEditingController();
  final _addEmailController = TextEditingController();
  final _addPhoneController = TextEditingController();
  final _addAddressController = TextEditingController();
  final _addDistrictController = TextEditingController();
  final _addAdhaarController = TextEditingController();
  final _addSkillController = TextEditingController();
  final _addExperienceController = TextEditingController();
  final _addHourlyRateController = TextEditingController();
  // Placeholder for profile picture state
  // File? _selectedProfilePic;

  // Create storage instance
  final _storage = const FlutterSecureStorage();
  static const String _storageEmailKey = 'saved_email';
  static const String _storageRememberKey = 'remember_me';

  String? _userName;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    print("AdminDashboard initState: Fetching initial stats...");
    _statsFuture = _fetchDashboardStats();
    _complaintsFuture = _fetchComplaints(); // Add this line
    _loadUserDataForDrawer(); // Load user data for drawer
  }

  // Method to handle refresh
  // Simpler version: Just update the future in setState.
  // The DashboardView will rebuild automatically because its parent state changed.
  Future<void> _handleRefreshStats() async {
    print("AdminDashboard: Refresh triggered. Fetching new stats...");
    if (mounted) {
      setState(() {
        // Only update the future. The DashboardView using this future will get rebuilt.
        _statsFuture = _fetchDashboardStats();
        _complaintsFuture = _fetchComplaints(); // Add this line
        print("AdminDashboard: New futures assigned in setState.");
      });
      // Await the new future *after* setState has been called.
      // This ensures the FutureBuilder gets the new future instance.
      try {
        await _statsFuture;
        await _complaintsFuture; // Add this line
        print("AdminDashboard: Awaited new futures completion.");
      } catch (e) {
        print("AdminDashboard: Error awaiting refreshed data: $e");
        // Error is handled by the FutureBuilder, but log here too.
      }
    } else {
      print("AdminDashboard: Refresh triggered but widget not mounted.");
    }
  }

  @override
  void dispose() {
    // Dispose new controllers
    _addFirstNameController.dispose();
    _addLastNameController.dispose();
    _addEmailController.dispose();
    _addPhoneController.dispose();
    _addAddressController.dispose();
    _addDistrictController.dispose();
    _addAdhaarController.dispose();
    _addSkillController.dispose();
    _addExperienceController.dispose();
    _addHourlyRateController.dispose();
    super.dispose();
  }

  // Function to handle logout
  Future<void> _logout(BuildContext context) async {
    print("Logout function called."); // Log start
    try {
      // Clear saved credentials from secure storage
      print("Clearing secure storage..."); // Log action
      await _storage.delete(key: _storageEmailKey);
      await _storage.delete(key: _storageRememberKey);
      print("Secure storage cleared."); // Log success

      // Navigate back to Login Page and remove all previous routes
      // Ensure context is still valid before navigating
      if (mounted) {
        print(
          "Widget is mounted. Navigating to LoginPage...",
        ); // Log navigation attempt
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (Route<dynamic> route) => false, // Remove all routes
        );
        print("Navigation command issued."); // Log after navigation call
      } else {
        print(
          "Logout attempted but widget is not mounted.",
        ); // Log if not mounted
      }
    } catch (e) {
      print("Error during logout: $e"); // Log error
      // Optionally show an error message to the user
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
      }
    }
  }

  // Add new method to fetch complaints
  Future<List<Map<String, dynamic>>> _fetchComplaints() async {
    try {
      print("Fetching recent activity from: $_baseApiUrl/dashboard/activity/");
      final response = await http.get(
        Uri.parse('$_baseApiUrl/dashboard/activity/'),
      );
      print("Response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isEmpty) {
          print("Warning: Received empty list from activity endpoint.");
          return [];
        }

        final result = data
            .map<Map<String, dynamic>>((item) => item as Map<String, dynamic>)
            .toList();
        print("Successfully parsed activity: ${result.length} items.");
        return result;
      } else {
        print('Failed to load activity: ${response.statusCode}');
        throw Exception('Failed to load activity: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching activity: $e');
      throw Exception('Error fetching activity: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Consume SettingsProvider to get the current primary color for the Drawer/FAB highlight
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    // Get the MaterialColor from the provider
    final MaterialColor primaryMaterialColor = settingsProvider.primaryColor;
    // Get the primary color shade (usually 500) for general use if needed
    final Color primaryColor = primaryMaterialColor; // MaterialColor is a Color

    // Build the list of screens dynamically within the build method
    final List<Widget> screens = [
      DashboardView(
        // Pass the current _statsFuture state variable
        statsFuture: _statsFuture,
        onAddWorkerPressed: () => _showAddWorkerDialog(context),
        // Pass the method reference for refreshing
        onRefreshStats: _handleRefreshStats,
        complaintsFuture: _complaintsFuture, // Add this line
      ),
      const FacultyScreen(), // Faculty management screen
      const StudentsScreen(), // Students management screen
      const SettingsScreen(), // Settings screen
    ];

    return Scaffold(
      backgroundColor: Theme.of(
        context,
      ).scaffoldBackgroundColor, // Use theme background
      appBar: AppBar(
        // AppBar color, foregroundColor, titleStyle, iconTheme are now handled by the theme in main.dart
        elevation: 1.0,
        shadowColor: Colors.black.withOpacity(0.1),
        title: Text(
          // Determine title based on selected index
          _getAppBarTitle(_selectedIndex),
        ),
        centerTitle: false,
        toolbarHeight: 70,
        actions: [
          // IconButton(
          //   icon: Icon(Icons.notifications), // Icon color from theme
          //   tooltip: 'Notifications',
          //   onPressed: () {},
          // ),
          GestureDetector(
            onTap: () {
              // Handle logout when tapped
              print("Logout icon tapped.");
              _logout(context);
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0, left: 8.0),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? primaryMaterialColor // Use MaterialColor here
                          .withOpacity(
                            0.3,
                          ) // Darker subtle background in dark mode
                    : Colors.white.withOpacity(
                        0.2,
                      ), // Lighter subtle background in light mode
                child: Icon(
                  Icons.logout,
                  // Use theme color if available, otherwise calculate based on brightness
                  color:
                      Theme.of(context).appBarTheme.iconTheme?.color ??
                      (Theme.of(context).brightness == Brightness.dark
                          ? primaryMaterialColor[200] // Use MaterialColor shade for dark mode
                          : Colors.white), // White for light mode
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
      // Pass the primary shade (Color) or MaterialColor based on what the drawer needs
      drawer: _buildDrawer(
        primaryMaterialColor,
      ), // Pass MaterialColor for selection highlight
      body: IndexedStack(index: _selectedIndex, children: screens),
      // FAB removed - no need to add faculty manually
      floatingActionButton: null,
      // Pass the primary shade (Color) or MaterialColor based on what the nav bar needs
      bottomNavigationBar: _buildBottomNavigationBar(
        primaryMaterialColor,
      ), // Pass MaterialColor for selection highlight
    );
  }

  // Helper to get AppBar title based on index
  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return 'Admin Dashboard';
      case 1:
        return 'Manage Faculty';
      case 2:
        return 'Manage Students';
      case 3:
        return 'Settings';
      default:
        return 'Admin Dashboard';
    }
  }

  // Method to build the Drawer - Accepts MaterialColor
  Widget _buildDrawer(MaterialColor headerColor) {
    // headerColor is now used for selection highlight AND header background
    final theme = Theme.of(context);
    final drawerTextColor = theme.brightness == Brightness.dark
        ? Colors.grey[300]
        : Colors.grey[800];
    final drawerIconColor = theme.brightness == Brightness.dark
        ? Colors.grey[400]
        : Colors.grey[700];

    return Drawer(
      // backgroundColor: theme.cardColor, // Use theme card color for drawer background
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          // Custom Drawer Header
          Container(
            height: 180, // Adjust height as needed
            decoration: BoxDecoration(
              color:
                  headerColor, // Use the passed MaterialColor for the header background
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                16.0,
                40.0,
                16.0,
                16.0,
              ), // Adjust padding for status bar
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 30, // Example size
                    backgroundColor: Colors.white.withOpacity(0.8),
                    child: Icon(
                      Ionicons.person_outline,
                      size: 32,
                      // Use a contrasting color based on the headerColor's brightness
                      color: headerColor.computeLuminance() > 0.5
                          ? Colors.black54
                          : headerColor[700], // Use a darker shade of the header color
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    _userName ?? 'Admin', // Use state variable or placeholder
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _userEmail ??
                        'admin@example.com', // Use state variable or placeholder
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Drawer Items - Pass selected state and color
          _buildDrawerItem(
            icon: Ionicons.grid_outline,
            text: 'Dashboard',
            selected: _selectedIndex == 0,
            selectedColor: headerColor, // Use passed color for selection
            defaultIconColor: drawerIconColor!,
            defaultTextColor: drawerTextColor!,
            onTap: () => _onSelectItem(0),
          ),
          _buildDrawerItem(
            icon: Ionicons.people_outline,
            text: 'Faculty Management',
            selected: _selectedIndex == 1,
            selectedColor: headerColor, // Use passed color for selection
            defaultIconColor: drawerIconColor,
            defaultTextColor: drawerTextColor,
            onTap: () => _onSelectItem(1),
          ),
          _buildDrawerItem(
            icon: Ionicons.school_outline,
            text: 'Students Management',
            selected: _selectedIndex == 2, // Update selected index check
            selectedColor: headerColor, // Use passed color for selection
            defaultIconColor: drawerIconColor,
            defaultTextColor: drawerTextColor,
            onTap: () => _onSelectItem(2),
          ),
          _buildDrawerItem(
            icon: Ionicons.document_text_outline,
            text: 'Attendance Reports',
            selected: false, // Assuming Reports is not a main screen index
            selectedColor: headerColor, // Use passed color for selection
            defaultIconColor: drawerIconColor,
            defaultTextColor: drawerTextColor,
            onTap: () {
              // You can add reports functionality here later
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Attendance Reports coming soon!'),
                ),
              );
              Navigator.pop(context);
            },
          ),
          Divider(color: theme.dividerColor), // Use theme divider color
          _buildDrawerItem(
            icon: Ionicons.settings_outline,
            text: 'Settings',
            selected: _selectedIndex == 3, // Update selected index check
            selectedColor: headerColor, // Use passed color for selection
            defaultIconColor: drawerIconColor,
            defaultTextColor: drawerTextColor,
            onTap: () => _onSelectItem(3),
          ),
          _buildDrawerItem(
            icon: Ionicons.log_out_outline,
            text: 'Logout',
            selected: false,
            selectedColor: headerColor, // Use passed color for selection
            defaultIconColor: drawerIconColor,
            defaultTextColor: drawerTextColor,
            onTap: () {
              print("Logout drawer item tapped."); // Log tap
              Navigator.pop(context); // Close drawer first
              _logout(context); // Call the logout function
            },
          ),
        ],
      ),
    );
  }

  // Helper method to build Drawer ListTiles with selection highlight
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

  // Updated method to handle drawer item taps
  void _onSelectItem(int index) {
    Navigator.pop(context); // Close the drawer

    // Handle navigation or state change based on index
    if (index >= 0 && index < 4) {
      // Indices 0, 1, 2, 3 correspond to the main screens
      setState(() {
        _selectedIndex = index;
      });
    } else if (index == 4) {
      // Index 4 is 'Jobs' in this example
      // TODO: Navigate to Jobs screen or handle differently
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Navigate to Jobs Screen (Not Implemented)')),
      );
      // Example: Navigator.push(context, MaterialPageRoute(builder: (_) => JobsScreen()));
    }
    // Logout is handled directly in its onTap
  }

  // Method to build the BottomNavigationBar - Accepts MaterialColor
  Widget _buildBottomNavigationBar(MaterialColor activeColor) {
    // activeColor used for selected item highlight if needed, but theme handles colors
    // Bottom nav colors are now primarily controlled by the theme's BottomNavigationBarThemeData
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) => setState(() => _selectedIndex = index),
      // selectedItemColor, unselectedItemColor, backgroundColor, labelStyles, type, elevation are set by theme
      items: [
        _buildNavItem(
          outlineIcon: Ionicons.grid_outline,
          filledIcon: Ionicons.grid,
          label: 'Dashboard',
          index: 0,
        ),
        _buildNavItem(
          outlineIcon: Ionicons.people_outline,
          filledIcon: Ionicons.people,
          label: 'Faculty',
          index: 1,
        ),
        _buildNavItem(
          outlineIcon: Ionicons.school_outline,
          filledIcon: Ionicons.school,
          label: 'Students',
          index: 2,
        ),
        _buildNavItem(
          outlineIcon: Ionicons.settings_outline,
          filledIcon: Ionicons.settings,
          label: 'Settings',
          index: 3,
        ),
      ],
    );
  }

  // Helper method to build BottomNavigationBarItem - simplified
  BottomNavigationBarItem _buildNavItem({
    required IconData outlineIcon,
    required IconData filledIcon,
    required String label,
    required int index,
  }) {
    // Theme handles the colors (selected/unselected)
    return BottomNavigationBarItem(
      icon: Icon(outlineIcon),
      activeIcon: Icon(filledIcon),
      label: label,
    );
  }

  // --- Add Worker Dialog ---
  void _showAddWorkerDialog(BuildContext context) {
    // Clear previous input and reset state
    _addFirstNameController.clear();
    _addLastNameController.clear();
    _addEmailController.clear();
    _addPhoneController.clear();
    _addAddressController.clear();
    _addDistrictController.clear();
    _addAdhaarController.clear();
    _addSkillController.clear();
    _addExperienceController.clear();
    _addHourlyRateController
        .clear(); // Reset profile pic state if using stateful approach
    // setState(() { _selectedProfilePic = null; });

    final ThemeData theme = Theme.of(context);
    final Color headerColor = theme.colorScheme.primary; // Use theme primary
    final Color headerForegroundColor =
        theme.colorScheme.onPrimary; // Use theme onPrimary
    final Color dialogBackgroundColor =
        theme.dialogBackgroundColor; // Use theme dialog background
    final Color inputFillColor =
        theme.inputDecorationTheme.fillColor ??
        theme.colorScheme.surfaceVariant; // Use theme input fill

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: dialogBackgroundColor, // Use theme dialog background
          elevation: 4, // Adjust elevation as needed
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ClipRRect(
            // Clip content to rounded corners
            borderRadius: BorderRadius.circular(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // --- Custom Header ---
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                  color: headerColor, // Use theme header color
                  child: Row(
                    children: [
                      Icon(
                        Ionicons.person_add_outline,
                        color: headerForegroundColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Add New Worker',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: headerForegroundColor,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Ionicons.close_outline,
                          color: headerForegroundColor,
                        ),
                        iconSize: 22,
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(dialogContext).pop(),
                      ),
                    ],
                  ),
                ),
                // --- Scrollable Form Content ---
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Use the themed _buildTextField helper
                        _buildThemedTextField(
                          dialogContext,
                          _addFirstNameController,
                          'First Name',
                          Ionicons.person_outline,
                        ),
                        const SizedBox(height: 12),
                        _buildThemedTextField(
                          dialogContext,
                          _addLastNameController,
                          'Last Name',
                          null,
                        ),
                        const SizedBox(height: 12),
                        _buildThemedTextField(
                          dialogContext,
                          _addEmailController,
                          'Email',
                          Ionicons.mail_outline,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 12),
                        _buildThemedTextField(
                          dialogContext,
                          _addPhoneController,
                          'Phone',
                          Ionicons.call_outline,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 12),
                        _buildThemedTextField(
                          dialogContext,
                          _addAddressController,
                          'Address',
                          Ionicons.home_outline,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12),
                        _buildThemedTextField(
                          dialogContext,
                          _addDistrictController,
                          'District',
                          Ionicons.location_outline,
                        ),
                        const SizedBox(height: 12),
                        _buildThemedTextField(
                          dialogContext,
                          _addAdhaarController,
                          'Aadhaar Number',
                          Ionicons.id_card_outline,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),
                        _buildThemedTextField(
                          dialogContext,
                          _addSkillController,
                          'Skills (comma-separated)',
                          Ionicons.construct_outline,
                        ),
                        const SizedBox(height: 12),
                        _buildThemedTextField(
                          dialogContext,
                          _addExperienceController,
                          'Experience',
                          Ionicons.briefcase_outline,
                        ),
                        const SizedBox(height: 12),
                        _buildThemedTextField(
                          dialogContext,
                          _addHourlyRateController,
                          'Hourly Rate',
                          Ionicons.cash_outline,
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Actions Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              child: const Text('Cancel'),
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              child: const Text('Add Worker'),
                              onPressed: () {
                                // TODO: Implement Add Worker API call
                                print('Add Worker Pressed');
                                // Validate input
                                // Call API
                                // Close dialog on success/failure
                                Navigator.of(
                                  dialogContext,
                                ).pop(); // Close for now
                                Fluttertoast.showToast(msg: "Add Worker TBD");
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    // Note: No need for whenComplete here to dispose controllers as they are part of the State class
  }

  // Helper widget for creating styled TextFields that respects theme
  Widget _buildThemedTextField(
    BuildContext context,
    TextEditingController controller,
    String label,
    IconData? icon, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      style: GoogleFonts.outfit(
        color: theme.textTheme.bodyLarge?.color,
        fontSize: 14.5,
      ), // Use theme text color
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        // InputDecoration uses theme by default
        labelText: label,
        // labelStyle: theme.inputDecorationTheme.labelStyle, // Uses theme
        prefixIcon: icon != null
            ? Icon(
                icon,
                color: theme.inputDecorationTheme.labelStyle?.color
                    ?.withOpacity(0.7),
                size: 20,
              ) // Use theme label color for icon
            : null,
        // contentPadding, filled, fillColor, border, enabledBorder, focusedBorder are set by theme
      ),
    );
  }

  // Load user data specifically for the drawer header
  Future<void> _loadUserDataForDrawer() async {
    final email = await _storage.read(key: _storageEmailKey);
    // final name = await _storage.read(key: 'user_name'); // If name is stored
    if (mounted) {
      setState(() {
        _userEmail = email;
        // _userName = name; // Set name if available
        // Derive placeholder name if needed
        if (_userEmail != null && _userName == null) {
          _userName = _userEmail!.split('@').first;
          _userName = _userName![0].toUpperCase() + _userName!.substring(1);
        }
      });
    }
  }

  // Add method to fetch dashboard stats
  Future<List<Map<String, dynamic>>> _fetchDashboardStats() async {
    // Add a small delay for testing loading indicator
    // await Future.delayed(const Duration(seconds: 2));
    try {
      print("Fetching dashboard stats from: $_baseApiUrl/dashboard/stats/");
      final response = await http.get(
        Uri.parse('$_baseApiUrl/dashboard/stats/'),
      );
      print("Response status: ${response.statusCode}");
      // Limit printing large bodies
      print(
        "Response body: ${response.body.substring(0, (response.body.length > 500 ? 500 : response.body.length))}",
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isEmpty) {
          print("Warning: Received empty list from stats endpoint.");
          // Return a specific state or empty list based on requirements
          return [];
        }
        final result = data.map<Map<String, dynamic>>((item) {
          IconData iconData = _getIconDataFromString(item['icon']);
          Color color = _colorFromHex(item['color']);
          return {
            'title': item['title'],
            'count': item['count'].toString(),
            'icon': iconData,
            'color': color,
            'growth': item['growth'],
          };
        }).toList();
        print("Successfully parsed stats: ${result.length} items.");
        return result;
      } else {
        print('Failed to load stats: ${response.statusCode}');
        throw Exception('Failed to load stats: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      // Catch stack trace
      print('Error fetching dashboard stats: $e');
      print('Stack trace: $stackTrace'); // Print stack trace
      // Rethrow to let FutureBuilder handle the error state
      throw Exception('Error fetching stats: $e');
    }
  }

  // Helper method to convert icon string to IconData
  IconData _getIconDataFromString(String iconName) {
    switch (iconName) {
      case 'person_outline':
        return Icons.person_outline;
      case 'business_center_outlined':
        return Icons.business_center_outlined;
      case 'pending_actions_outlined':
        return Icons.pending_actions_outlined;
      case 'work_outline':
        return Icons.work_outline;
      default:
        return Icons.error_outline;
    }
  }

  // Helper method to convert hex color string to Color
  Color _colorFromHex(String hexString) {
    hexString = hexString.replaceFirst('#', '');
    if (hexString.length == 6) {
      hexString = 'FF' + hexString;
    }
    return Color(int.parse(hexString, radix: 16));
  }
} // End of _AdminDashboardState

// DashboardView class
class DashboardView extends StatelessWidget {
  final Future<List<Map<String, dynamic>>> statsFuture;
  final VoidCallback? onAddWorkerPressed;
  final Future<void> Function()? onRefreshStats;
  final Future<List<Map<String, dynamic>>> complaintsFuture; // Add this line

  const DashboardView({
    Key? key,
    required this.statsFuture,
    this.onAddWorkerPressed,
    this.onRefreshStats,
    required this.complaintsFuture, // Add this line
  }) : super(key: key);

  // Helper method to build profile picture with fallback
  Widget _buildProfilePicture({
    required String? imageUrl,
    required double radius,
    required Color backgroundColor,
    required IconData fallbackIcon,
    required Color iconColor,
  }) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        child: ClipOval(
          child: Image.network(
            imageUrl,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Icon(fallbackIcon, size: radius, color: iconColor);
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: radius * 2,
                height: radius * 2,
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                              (loadingProgress.expectedTotalBytes ?? 1)
                        : null,
                    strokeWidth: 2.0,
                    valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                  ),
                ),
              );
            },
          ),
        ),
      );
    } else {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        child: Icon(fallbackIcon, size: radius, color: iconColor),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print("DashboardView build: Using future instance $statsFuture");
    if (onRefreshStats == null) {
      print("DashboardView build: WARNING - onRefreshStats is NULL.");
    }
    return RefreshIndicator(
      onRefresh: () async {
        print("RefreshIndicator triggered");
        if (onRefreshStats != null) {
          await onRefreshStats!();
          print("RefreshIndicator completed after awaiting onRefreshStats");
        } else {
          print(
            "RefreshIndicator: ERROR - onRefreshStats callback is null during onRefresh.",
          );
          await Future.delayed(const Duration(seconds: 1));
        }
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeHeader(context), // Pass context
              const SizedBox(height: 24),
              _buildStatsSection(context), // Pass context
              const SizedBox(height: 24),
              // _buildQuickActions(context), // Pass context
              const SizedBox(height: 24),
              _buildRecentActivityList(context), // Pass context
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    print("Building _buildStatsSection with future: $statsFuture");
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: statsFuture, // Use the future passed to the widget
      builder: (context, snapshot) {
        print("FutureBuilder state: ${snapshot.connectionState}");

        // Handle different states
        if (snapshot.connectionState == ConnectionState.waiting) {
          print("FutureBuilder: Waiting for stats...");
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40.0), // Add padding
              child: CircularProgressIndicator(),
            ),
          );
        } else if (snapshot.hasError) {
          print("FutureBuilder: Error loading stats: ${snapshot.error}");
          print(
            "FutureBuilder: StackTrace: ${snapshot.stackTrace}",
          ); // Log stack trace
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 20.0,
                horizontal: 16.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Ionicons.cloud_offline_outline,
                    color: Colors.red.shade300,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error Loading Statistics',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Could not fetch data. Please check your connection and try again.\nError: ${snapshot.error}',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  // Add a retry button maybe?
                  ElevatedButton.icon(
                    icon: Icon(Ionicons.refresh, size: 18),
                    label: Text("Retry"),
                    onPressed: onRefreshStats, // Allow retry via refresh
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(
                        context,
                      ).primaryColor.withOpacity(0.1),
                      foregroundColor: Theme.of(context).primaryColor,
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          print("FutureBuilder: No stats data received or data is empty.");
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Ionicons.information_circle_outline,
                    color: Colors.grey.shade400,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No statistics available.',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Data loaded successfully
        final stats = snapshot.data!;
        print("FutureBuilder: Successfully loaded ${stats.length} stats.");

        // Build the GridView
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // Explicitly set cross axis count to 2
            childAspectRatio: 1.3, // Adjust aspect ratio as needed
            crossAxisSpacing: 16, // Add spacing between cards horizontally
            mainAxisSpacing: 16, // Add spacing between cards vertically
          ),
          itemCount: stats.length,
          itemBuilder: (context, index) {
            final stat = stats[index];
            if (stat['title'] != null &&
                stat['count'] != null &&
                stat['icon'] != null &&
                stat['color'] != null &&
                stat['growth'] != null) {
              return _buildStatCard(
                // Pass context
                context: context,
                title: stat['title'],
                count: stat['count'],
                icon: stat['icon'],
                color: stat['color'],
                growth: stat['growth'],
              );
            } else {
              // Handle malformed stat item
              print("Warning: Malformed stat item at index $index: $stat");
              return Card(
                // Use Card for consistent theme background
                elevation: 1,
                child: Center(
                  child: Text(
                    'Invalid data',
                    style: TextStyle(color: Colors.red.shade300),
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildWelcomeHeader(BuildContext context) {
    final theme = Theme.of(context);
    // Use text theme colors which adapt to brightness
    final Color primaryTextColor = theme.textTheme.bodyLarge!.color!;
    final Color secondaryTextColor = theme.textTheme.bodySmall!.color!;
    const String imageUrl =
        'https://th.bing.com/th/id/OIP.AMIHpcIURM_d5NVzzAg0wAHaHa?pid=ImgDet&w=184&h=184&c=7&dpr=1.3'; // Image URL

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      decoration: BoxDecoration(
        color: theme.cardColor, // Explicitly use theme card color
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Image on the left
          ClipOval(
            child: Image.network(
              imageUrl,
              width: 50, // Adjust size as needed
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.construction, size: 40), // Placeholder icon
            ),
          ),
          const SizedBox(width: 16),
          // Text content in the middle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, Admin!',
                  style: GoogleFonts.outfit(
                    color: primaryTextColor, // Use adaptive text color
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Here\'s your system overview.',
                  style: GoogleFonts.outfit(
                    color: secondaryTextColor, // Use adaptive text color
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          // ... optional trailing icon ...
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required String count,
    required IconData icon,
    required Color color, // Accent color
    required String growth,
  }) {
    final theme = Theme.of(context);
    final Color cardBackgroundColor =
        theme.cardColor; // Explicitly use theme card color
    // Use text theme colors which adapt to brightness
    final Color primaryTextColor = theme.textTheme.bodyLarge!.color!;
    final Color secondaryTextColor = theme.textTheme.bodySmall!.color!;
    final bool isDark =
        theme.brightness ==
        Brightness.dark; // Adjust accent color opacity based on theme
    final Color accentColor = isDark ? color.withOpacity(0.7) : color;
    final Color iconBgColor = isDark ? color.withOpacity(0.8) : color;

    // Define border color based on theme
    final Color borderColor = isDark
        ? Colors.white.withOpacity(0.05) // Lighter border for dark mode
        : theme.dividerColor.withOpacity(0.5); // Existing border for light mode

    return Container(
      decoration: BoxDecoration(
        color: cardBackgroundColor, // Explicitly use theme card color
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            spreadRadius: 1,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: borderColor,
          width: 1.0,
        ), // Use conditional border color
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Faded circle background effect
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Main content Padding
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left side: Text content and growth
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: secondaryTextColor, // Use adaptive text color
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        count,
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: primaryTextColor, // Use adaptive text color
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        growth,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: growth.startsWith('+')
                              ? (isDark
                                    ? Colors.green.shade300
                                    : Colors.green.shade700)
                              : (isDark
                                    ? Colors.red.shade300
                                    : Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Right side: Icon with background
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: iconBgColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildQuickActions(BuildContext context) {
  //   final theme = Theme.of(context);
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(
  //         'Quick Actions',
  //         style: GoogleFonts.outfit(
  //           fontSize: 18,
  //           fontWeight: FontWeight.w600,
  //           color: theme.textTheme.bodyLarge?.color, // Use theme color
  //         ),
  //       ),
  //       SizedBox(height: 16),
  //       Row(
  //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //         children: [
  //           // Action cards - colors are fixed but should contrast well
  //           _buildActionCard(
  //             context: context,
  //             icon: Icons.person_add_alt_1_outlined,
  //             label: 'Add Worker',
  //             color: Color(0xFF4A6FE6), // Blue
  //             onTap: onAddWorkerPressed,
  //           ),
  //           _buildActionCard(
  //             context: context,
  //             icon: Icons.business_outlined,
  //             label: 'Add Contractor',
  //             color: Color(0xFFE67E22), // Orange
  //             onTap: () {
  //               Fluttertoast.showToast(msg: "Add Contractor TBD");
  //             },
  //           ),
  //           _buildActionCard(
  //             context: context,
  //             icon: Icons.approval_outlined,
  //             label: 'Approvals',
  //             color: Color(0xFF2ECC71), // Green
  //             onTap: () {
  //               Fluttertoast.showToast(msg: "Approvals TBD");
  //             },
  //           ),
  //           _buildActionCard(
  //             context: context,
  //             icon: Ionicons.people_circle_outline,
  //             label: 'View Users',
  //             color: Colors.teal.shade400, // Teal color
  //             onTap: () {
  //               Fluttertoast.showToast(msg: "View Users TBD");
  //             },
  //           ),
  //         ],
  //       ),
  //     ],
  //   );
  // }

  // Modify _buildActionCard to use theme text color
  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color, // Accent color for icon background
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    // Use adaptive text color
    final Color textColor = theme.textTheme.bodySmall!.color!;
    final bool isDark = theme.brightness == Brightness.dark;
    final Color iconBgColor = isDark ? color.withOpacity(0.8) : color;

    return Expanded(
      child: InkWell(
        onTap: onTap ?? () {},
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: iconBgColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: textColor, // Use adaptive text color
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivityList(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodyLarge?.color, // Use theme color
          ),
        ),
        SizedBox(height: 16),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: complaintsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40.0),
                  child: CircularProgressIndicator(),
                ),
              );
            } else if (snapshot.hasError) {
              print("Error loading activity: ${snapshot.error}");
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red.shade300,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error Loading Activity',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Ionicons.information_circle_outline,
                        color: Colors.grey.shade400,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No recent activity.',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Data loaded successfully
            final complaints = snapshot.data!;
            return Column(
              children: List.generate(
                complaints.length > 5 ? 5 : complaints.length,
                (index) {
                  final complaint = complaints[index];
                  final bool isDark = theme.brightness == Brightness.dark;
                  final Color primaryColor = theme.colorScheme.primary;

                  // Determine icon, color, and gradient based on activity type
                  IconData icon;
                  Color iconColor;
                  LinearGradient iconGradient;
                  final type = complaint['complaint_type'] ?? 'Other';
                  final status = complaint['status'] ?? 'Pending';

                  switch (type) {
                    case 'Registration':
                      icon = Ionicons.person_add;
                      iconColor = Color(0xFF2ECC71);
                      iconGradient = LinearGradient(
                        colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      );
                      break;
                    case 'Enrollment':
                      icon = Ionicons.school;
                      iconColor = Color(0xFF3498DB);
                      iconGradient = LinearGradient(
                        colors: [Color(0xFF3498DB), Color(0xFF2980B9)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      );
                      break;
                    case 'Report':
                      icon = Ionicons.document_text;
                      iconColor = Color(0xFFF39C12);
                      iconGradient = LinearGradient(
                        colors: [Color(0xFFF39C12), Color(0xFFE67E22)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      );
                      break;
                    case 'Approval':
                      icon = Ionicons.checkmark_circle;
                      iconColor = Color(0xFF27AE60);
                      iconGradient = LinearGradient(
                        colors: [Color(0xFF27AE60), Color(0xFF1E8449)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      );
                      break;
                    case 'Attendance':
                      icon = Ionicons.alert_circle;
                      iconColor = Color(0xFFE74C3C);
                      iconGradient = LinearGradient(
                        colors: [Color(0xFFE74C3C), Color(0xFFC0392B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      );
                      break;
                    default:
                      icon = Ionicons.information_circle;
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
                        color: status == 'Pending'
                            ? iconColor.withOpacity(0.3)
                            : (isDark
                                  ? Colors.grey.shade800.withOpacity(0.3)
                                  : Colors.grey.shade200),
                        width: status == 'Pending' ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: status == 'Pending'
                              ? (isDark
                                    ? iconColor.withOpacity(0.15)
                                    : iconColor.withOpacity(0.1))
                              : (isDark
                                    ? Colors.black.withOpacity(0.2)
                                    : Colors.black.withOpacity(0.04)),
                          blurRadius: status == 'Pending' ? 12 : 8,
                          offset: Offset(0, status == 'Pending' ? 4 : 2),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
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
                                child: Icon(
                                  icon,
                                  color: Colors.white,
                                  size: 28,
                                ),
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
                                            complaint['title'] ?? 'Activity',
                                            style: GoogleFonts.outfit(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: theme
                                                  .textTheme
                                                  .bodyLarge
                                                  ?.color,
                                              letterSpacing: -0.3,
                                            ),
                                          ),
                                        ),
                                        if (status == 'Pending')
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
                                                  color: primaryColor
                                                      .withOpacity(0.4),
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
                                      complaint['description'] ??
                                          'No description',
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        color: theme.textTheme.bodySmall?.color,
                                        height: 1.5,
                                        fontWeight: FontWeight.w400,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
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
                                            ? Colors.grey.shade800.withOpacity(
                                                0.3,
                                              )
                                            : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Ionicons.time_outline,
                                            size: 12,
                                            color: theme
                                                .textTheme
                                                .bodySmall
                                                ?.color
                                                ?.withOpacity(0.6),
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            _formatTimeAgo(
                                              complaint['created_at'],
                                            ),
                                            style: GoogleFonts.outfit(
                                              fontSize: 12,
                                              color: theme
                                                  .textTheme
                                                  .bodySmall
                                                  ?.color
                                                  ?.withOpacity(0.6),
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
                },
              ),
            );
          },
        ),
      ],
    );
  }

  String _formatTimeAgo(String? dateTimeString) {
    if (dateTimeString == null) return 'just now';
    try {
      final dateTime = DateTime.parse(dateTimeString);
      final now = DateTime.now();
      final diff = now.difference(dateTime);

      if (diff.inSeconds < 60) {
        return 'just now';
      } else if (diff.inMinutes < 60) {
        return '${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''} ago';
      } else if (diff.inHours < 24) {
        return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
      } else if (diff.inDays < 7) {
        return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
      } else {
        return DateFormat('MMM d, yyyy').format(dateTime);
      }
    } catch (e) {
      return 'recently';
    }
  }

  void _showComplaintDetailsDialog(
    BuildContext context,
    Map<String, dynamic> complaint,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      complaint['subject'] ?? 'No Subject',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(complaint['status'] ?? 'Pending'),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      complaint['status'] ?? 'Pending',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Complaint Type
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.category_outlined,
                      size: 16,
                      color: theme.primaryColor,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Type: ${complaint['complaint_type'] ?? 'Other'}',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),

              // Description section
              Text(
                'Complaint Details',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
              SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Text(
                  complaint['description'] ?? 'No description provided.',
                  style: GoogleFonts.outfit(fontSize: 14),
                ),
              ),
              SizedBox(height: 16),

              // Reporter section - Fix dark theme
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.blue.withOpacity(0.15)
                      : Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? Colors.blue[700]! : Colors.blue[200]!,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Worker profile picture
                        _buildProfilePicture(
                          imageUrl: complaint['worker_profile_pic'],
                          radius: 20,
                          backgroundColor: isDark
                              ? Colors.blue[800]!
                              : Colors.blue[100]!,
                          fallbackIcon: Icons.person,
                          iconColor: isDark
                              ? Colors.blue[200]!
                              : Colors.blue[700]!,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Reported By (Worker)',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.blue[300]
                                      : Colors.blue[700],
                                ),
                              ),
                              Text(
                                '${complaint['worker_name'] ?? 'Unknown'}',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: theme.textTheme.bodyMedium?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (complaint['worker_email'] != null) ...[
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.email_outlined,
                            size: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          SizedBox(width: 4),
                          Text(
                            complaint['worker_email'],
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (complaint['worker_phone'] != null &&
                        complaint['worker_phone'] != 'N/A') ...[
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.phone_outlined,
                            size: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          SizedBox(width: 4),
                          Text(
                            complaint['worker_phone'],
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 12),

              // Contractor section - Fix dark theme
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.orange.withOpacity(0.15)
                      : Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? Colors.orange[700]! : Colors.orange[200]!,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Contractor profile picture
                        _buildProfilePicture(
                          imageUrl: complaint['contractor_profile_pic'],
                          radius: 20,
                          backgroundColor: isDark
                              ? Colors.orange[800]!
                              : Colors.orange[100]!,
                          fallbackIcon: Icons.business,
                          iconColor: isDark
                              ? Colors.orange[200]!
                              : Colors.orange[700]!,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Reported Against (Contractor)',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.orange[300]
                                      : Colors.orange[700],
                                ),
                              ),
                              Text(
                                '${complaint['contractor_name'] ?? 'Unknown'}',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: theme.textTheme.bodyMedium?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (complaint['contractor_email'] != null) ...[
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.email_outlined,
                            size: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          SizedBox(width: 4),
                          Text(
                            complaint['contractor_email'],
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (complaint['contractor_phone'] != null &&
                        complaint['contractor_phone'] != 'N/A') ...[
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.phone_outlined,
                            size: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          SizedBox(width: 4),
                          Text(
                            complaint['contractor_phone'],
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 16),
              // Date submitted
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Submitted: ${_formatDate(complaint['created_at'])}',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Close'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showStatusUpdateDialog(context, complaint);
                      },
                      icon: Icon(Icons.edit_outlined, size: 16),
                      label: Text('Take Action'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Resolved':
        return Colors.green[400]!;
      case 'In Review':
        return Colors.orange[400]!;
      case 'Rejected':
        return Colors.red[400]!;
      default:
        return Colors.amber[400]!; // Pending
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown date';
    try {
      final date = DateTime.parse(dateString);
      return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}"
          .replaceAll(' 0', ' '); // Remove leading zero in hour if present
    } catch (e) {
      print("Error parsing date: $e");
      return 'Invalid date';
    }
  }

  void _showStatusUpdateDialog(
    BuildContext context,
    Map<String, dynamic> complaint,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    String selectedStatus = complaint['status'] ?? 'Pending';
    final statusOptions = ['Pending', 'In Review', 'Resolved', 'Rejected'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      Icons.edit_outlined,
                      color: theme.primaryColor,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Update Complaint Status',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Current complaint info
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Complaint: ${complaint['subject'] ?? 'No Subject'}',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Current Status: ${complaint['status'] ?? 'Pending'}',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),

                // Status selection
                Text(
                  'Select New Status',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
                SizedBox(height: 8),

                // Status options
                ...statusOptions
                    .map(
                      (status) => InkWell(
                        onTap: () {
                          setState(() {
                            selectedStatus = status;
                          });
                        },
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          margin: EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: selectedStatus == status
                                ? Colors.white.withOpacity(0.05)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selectedStatus == status
                                  ? theme.primaryColor
                                  : theme.dividerColor,
                              width: selectedStatus == status ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                selectedStatus == status
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: selectedStatus == status
                                    ? Colors.green
                                    : theme.textTheme.bodySmall?.color,
                                size: 20,
                              ),
                              SizedBox(width: 12),
                              Text(
                                status,
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: selectedStatus == status
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: selectedStatus == status
                                      ? isDark
                                            ? Colors.white
                                            : theme.primaryColor
                                      : theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                              Spacer(),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(status),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  status,
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),

                SizedBox(height: 20),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel'),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: selectedStatus != complaint['status']
                            ? () {
                                Navigator.pop(context);
                                _updateComplaintStatus(
                                  context,
                                  complaint['id'],
                                  selectedStatus,
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text('Update Status'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _updateComplaintStatus(
    BuildContext context,
    int complaintId,
    String newStatus,
  ) async {
    try {
      print('Updating complaint $complaintId to status: $newStatus');

      // Show loading toast
      Fluttertoast.showToast(
        msg: 'Updating complaint status...',
        backgroundColor: Colors.orange,
        textColor: Colors.white,
        gravity: ToastGravity.BOTTOM,
      );

      final response = await http.put(
        Uri.parse(
          'http://workersapp.pythonanywhere.com/api/complaints/$complaintId/update-status/',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'status': newStatus}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Status updated successfully: ${data['message']}');

        // Show success toast
        Fluttertoast.showToast(
          msg: 'Complaint status updated to $newStatus',
          backgroundColor: Colors.green,
          textColor: Colors.white,
          gravity: ToastGravity.BOTTOM,
        );

        // Refresh the complaints list by calling the refresh callback
        if (onRefreshStats != null) {
          await onRefreshStats!();
        }
      } else {
        final data = jsonDecode(response.body);
        print('Failed to update status: ${data['error']}');

        Fluttertoast.showToast(
          msg: data['error'] ?? 'Failed to update complaint status',
          backgroundColor: Colors.red,
          textColor: Colors.white,
          gravity: ToastGravity.BOTTOM,
        );
      }
    } catch (e) {
      print('Error updating complaint status: $e');
      Fluttertoast.showToast(
        msg: 'Error: $e',
        backgroundColor: Colors.red,
        textColor: Colors.white,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }
}
