import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';
import 'package:attendance_tracking/providers/settings_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserSettingsScreen extends StatefulWidget {
  final String? userName;
  final String? userEmail;

  const UserSettingsScreen({super.key, this.userName, this.userEmail});

  @override
  State<UserSettingsScreen> createState() => _UserSettingsScreenState();
}

class _UserSettingsScreenState extends State<UserSettingsScreen> {
  final _storage = const FlutterSecureStorage();
  static const String _storageEmailKey = 'saved_email';
  String? _userName;
  String? _userEmail;
  String? _profilePicUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final email = await _storage.read(key: _storageEmailKey);
    if (mounted) {
      setState(() {
        _userEmail = email;
        if (_userEmail != null && _userName == null) {
          _userName = _userEmail!.split('@').first;
          _userName = _userName![0].toUpperCase() + _userName!.substring(1);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: settingsProvider.primaryColor.withOpacity(
                    0.1,
                  ),
                  child: Text(
                    widget.userName?.isNotEmpty == true
                        ? widget.userName![0].toUpperCase()
                        : 'U',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: settingsProvider.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.userName ?? 'User',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color:
                              theme.textTheme.titleLarge?.color ??
                              (isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.userEmail ?? 'user@example.com',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color:
                              theme.textTheme.bodyMedium?.color ??
                              (isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    // TODO: Implement edit profile
                  },
                  icon: Icon(
                    Ionicons.create_outline,
                    color: settingsProvider.primaryColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
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
}
