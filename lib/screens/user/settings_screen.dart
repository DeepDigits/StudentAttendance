import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';
import 'package:attendance_tracking/providers/settings_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:attendance_tracking/config/api_config.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class UserSettingsScreen extends StatefulWidget {
  final String? userName;
  final String? userEmail;
  final String? userId;

  const UserSettingsScreen({
    super.key,
    this.userName,
    this.userEmail,
    this.userId,
  });

  @override
  State<UserSettingsScreen> createState() => _UserSettingsScreenState();
}

class _UserSettingsScreenState extends State<UserSettingsScreen> {
  final _storage = const FlutterSecureStorage();
  static const String _storageEmailKey = 'saved_email';

  // Profile data from API
  String? _userName;
  String? _userEmail;
  String? _profilePicUrl;
  String? _department;
  String? _studentId;
  String? _phone;
  String? _section;
  String? _yearOfStudy;
  String? _firstName;
  String? _lastName;
  String? _username;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchUserProfile();
  }

  Future<void> _loadUserData() async {
    final email = await _storage.read(key: _storageEmailKey);
    if (mounted) {
      setState(() {
        _userEmail = email ?? widget.userEmail;
        _userName = widget.userName;
      });
    }
  }

  Future<void> _fetchUserProfile() async {
    if (widget.userId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http
          .get(
            Uri.parse(
              '${ApiConfig.baseUrl}/api/student-profile/${widget.userId}/',
            ),
            headers: {'Accept': 'application/json'},
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        setState(() {
          _userName = data['fullName'] ?? widget.userName;
          _userEmail = data['email'] ?? widget.userEmail;
          _profilePicUrl = data['profilePicUrl'];
          _department = data['department'];
          _studentId = data['studentId'];
          _phone = data['phone'];
          _section = data['section'];
          _yearOfStudy = data['yearOfStudy'];
          _firstName = data['firstName'];
          _lastName = data['lastName'];
          _username = data['username'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching profile: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color textColor =
        theme.textTheme.bodyLarge?.color ??
        (isDark ? Colors.white : Colors.black87);
    final Color subtleTextColor =
        theme.textTheme.bodyMedium?.color ??
        (isDark ? Colors.grey.shade400 : Colors.grey.shade600);

    if (_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(50.0),
          child: SpinKitFadingCircle(
            color: settingsProvider.primaryColor,
            size: 50.0,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Section with Photo
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile Picture
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        settingsProvider.primaryColor.withOpacity(0.7),
                        settingsProvider.primaryColor.withOpacity(0.3),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: isDark ? Colors.grey[800] : Colors.white,
                    backgroundImage: _profilePicUrl != null
                        ? NetworkImage(_profilePicUrl!)
                        : null,
                    child: _profilePicUrl == null
                        ? Text(
                            (_userName ?? widget.userName ?? 'U')[0]
                                .toUpperCase(),
                            style: GoogleFonts.outfit(
                              fontSize: 36,
                              fontWeight: FontWeight.w600,
                              color: settingsProvider.primaryColor,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                // Name
                Text(
                  _userName ?? widget.userName ?? 'User',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                // Email
                Text(
                  _userEmail ?? widget.userEmail ?? 'user@example.com',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: subtleTextColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          _buildSectionHeader(context, 'Personal Information'),

          // Personal Details Card
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                _buildDetailRow(
                  context,
                  icon: Ionicons.person_outline,
                  label: 'First Name',
                  value: _firstName ?? 'Not set',
                  iconColor: settingsProvider.primaryColor,
                ),
                _buildDivider(isDark),
                _buildDetailRow(
                  context,
                  icon: Ionicons.person_outline,
                  label: 'Last Name',
                  value: _lastName ?? 'Not set',
                  iconColor: settingsProvider.primaryColor,
                ),
                _buildDivider(isDark),
                _buildDetailRow(
                  context,
                  icon: Ionicons.at_outline,
                  label: 'Username',
                  value: _username ?? 'Not set',
                  iconColor: Colors.teal,
                ),
                _buildDivider(isDark),
                _buildDetailRow(
                  context,
                  icon: Ionicons.mail_outline,
                  label: 'Email',
                  value: _userEmail ?? widget.userEmail ?? 'Not set',
                  iconColor: Colors.red,
                ),
                _buildDivider(isDark),
                _buildDetailRow(
                  context,
                  icon: Ionicons.call_outline,
                  label: 'Phone',
                  value: _phone ?? 'Not set',
                  iconColor: Colors.purple,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          _buildSectionHeader(context, 'Academic Information'),

          // Academic Details Card
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                _buildDetailRow(
                  context,
                  icon: Ionicons.id_card_outline,
                  label: 'Student ID / Roll Number',
                  value: _studentId ?? 'Not set',
                  iconColor: Colors.indigo,
                ),
                _buildDivider(isDark),
                _buildDetailRow(
                  context,
                  icon: Ionicons.school_outline,
                  label: 'Department',
                  value: _department ?? 'Not set',
                  iconColor: Colors.blue,
                ),
                _buildDivider(isDark),
                _buildDetailRow(
                  context,
                  icon: Ionicons.calendar_outline,
                  label: 'Year of Study',
                  value: _yearOfStudy ?? 'Not set',
                  iconColor: Colors.green,
                ),
                _buildDivider(isDark),
                _buildDetailRow(
                  context,
                  icon: Ionicons.grid_outline,
                  label: 'Section',
                  value: _section ?? 'Not set',
                  iconColor: Colors.orange,
                ),
              ],
            ),
          ),

          _buildSectionHeader(context, 'Appearance'),
          _buildSettingsCard(
            context: context,
            child: ListTile(
              leading: Icon(
                isDark ? Ionicons.moon_outline : Ionicons.sunny_outline,
                color: theme.colorScheme.primary,
              ),
              title: Text('Dark Mode', style: GoogleFonts.inter()),
              trailing: Switch(
                value: settingsProvider.themeMode == ThemeMode.dark,
                onChanged: (value) {
                  settingsProvider.setThemeMode(
                    value ? ThemeMode.dark : ThemeMode.light,
                  );
                },
                activeColor: theme.colorScheme.primary,
                inactiveThumbColor: Colors.grey.shade400,
                inactiveTrackColor: Colors.grey.shade300,
                activeTrackColor: theme.colorScheme.primary.withOpacity(0.5),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionHeader(context, 'Primary Color'),
          const SizedBox(height: 16),
          _buildSettingsCard(
            context: context,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Wrap(
                spacing: 12.0,
                runSpacing: 12.0,
                alignment: WrapAlignment.center,
                children: settingsProvider.availableColors.map((color) {
                  bool isSelected = settingsProvider.primaryColor == color;
                  return InkWell(
                    onTap: () => settingsProvider.setPrimaryColor(color),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? (isDark ? Colors.white : Colors.black54)
                              : Colors.transparent,
                          width: 2.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withOpacity(0.5),
                                  blurRadius: 5,
                                  spreadRadius: 1,
                                ),
                              ]
                            : [],
                      ),
                      child: isSelected
                          ? Icon(
                              Ionicons.checkmark,
                              color: isDark ? Colors.black : Colors.white,
                              size: 20,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // _buildSectionHeader(context, 'Account'),
          // _buildSettingsCard(
          //   context: context,
          //   child: ListTile(
          //     leading: Icon(Ionicons.person_circle_outline,
          //         color: theme.iconTheme.color),
          //     title: Text('Edit Profile', style: GoogleFonts.inter()),
          //     trailing: Icon(Ionicons.chevron_forward,
          //         size: 18, color: theme.iconTheme.color?.withOpacity(0.6)),
          //     onTap: () {
          //       ScaffoldMessenger.of(context).showSnackBar(
          //         const SnackBar(
          //             content: Text('Edit Profile Tapped (Not Implemented)')),
          //       );
          //     },
          //   ),
          // ),
          // _buildSettingsCard(
          //   context: context,
          //   child: ListTile(
          //     leading: Icon(Ionicons.key_outline, color: theme.iconTheme.color),
          //     title: Text('Change Password', style: GoogleFonts.inter()),
          //     trailing: Icon(Ionicons.chevron_forward,
          //         size: 18, color: theme.iconTheme.color?.withOpacity(0.6)),
          //     onTap: () {
          //       ScaffoldMessenger.of(context).showSnackBar(
          //         const SnackBar(
          //             content:
          //                 Text('Change Password Tapped (Not Implemented)')),
          //       );
          //     },
          //   ),
          // ),
          // _buildSettingsCard(
          //   context: context,
          //   child: ListTile(
          //     leading: Icon(Ionicons.notifications_outline,
          //         color: theme.iconTheme.color),
          //     title:
          //         Text('Notification Preferences', style: GoogleFonts.inter()),
          //     trailing: Icon(Ionicons.chevron_forward,
          //         size: 18, color: theme.iconTheme.color?.withOpacity(0.6)),
          //     onTap: () {
          //       ScaffoldMessenger.of(context).showSnackBar(
          //         const SnackBar(
          //             content: Text('Notifications Tapped (Not Implemented)')),
          //       );
          //     },
          //   ),
          // ),
          // const SizedBox(height: 16),
          // _buildSectionHeader(context, 'Support'),
          // _buildSettingsCard(
          //   context: context,
          //   child: ListTile(
          //     leading: Icon(Ionicons.help_circle_outline,
          //         color: theme.iconTheme.color),
          //     title: Text('Help & Support', style: GoogleFonts.inter()),
          //     trailing: Icon(Ionicons.chevron_forward,
          //         size: 18, color: theme.iconTheme.color?.withOpacity(0.6)),
          //     onTap: () {
          //       ScaffoldMessenger.of(context).showSnackBar(
          //         const SnackBar(
          //             content: Text('Help Tapped (Not Implemented)')),
          //       );
          //     },
          //   ),
          // ),
          // _buildSettingsCard(
          //   context: context,
          //   child: ListTile(
          //     leading: Icon(Ionicons.document_text_outline,
          //         color: theme.iconTheme.color),
          //     title: Text('Terms of Service', style: GoogleFonts.inter()),
          //     trailing: Icon(Ionicons.chevron_forward,
          //         size: 18, color: theme.iconTheme.color?.withOpacity(0.6)),
          //     onTap: () {
          //       ScaffoldMessenger.of(context).showSnackBar(
          //         const SnackBar(
          //             content: Text('Terms Tapped (Not Implemented)')),
          //       );
          //     },
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 8.0, left: 4.0),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: theme.textTheme.bodySmall?.color?.withOpacity(0.8),
        ),
      ),
    );
  }

  Widget _buildSettingsCard({
    required BuildContext context,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.only(bottom: 8.0),
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: child,
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color textColor =
        theme.textTheme.bodyLarge?.color ??
        (isDark ? Colors.white : Colors.black87);
    final Color subtleTextColor =
        theme.textTheme.bodyMedium?.color ??
        (isDark ? Colors.grey.shade400 : Colors.grey.shade600);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: subtleTextColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 56,
      color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
    );
  }
}
