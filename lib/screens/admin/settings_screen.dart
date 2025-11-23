import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';
import 'package:attendance_tracking/providers/settings_provider.dart';
import 'package:attendance_tracking/screens/login_page.dart'; // Import LoginPage for logout

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _storage = const FlutterSecureStorage();
  String? _userEmail;
  String? _userName; // Assuming name might be stored or derivable

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    // Attempt to load user email (and potentially name if stored)
    // Assuming email is stored under 'saved_email' key from login_page.dart
    final email = await _storage.read(key: 'saved_email');
    // You might need to store/retrieve the user's name similarly if needed
    // final name = await _storage.read(key: 'user_name');
    if (mounted) {
      setState(() {
        _userEmail = email;
        // _userName = name; // Set name if available (e.g., from login response)
        // For now, derive a placeholder name from email if email exists
        if (_userEmail != null && _userName == null) {
          _userName = _userEmail!.split('@').first; // Simple placeholder
          _userName =
              _userName![0].toUpperCase() +
              _userName!.substring(1); // Capitalize
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final theme = Theme.of(context);
    final isDarkMode =
        settingsProvider.themeMode == ThemeMode.dark ||
        (settingsProvider.themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    return Scaffold(
      // AppBar is handled by AdminDashboard
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionTitle('User Information'),
          _buildUserInfoCard(theme), // Ensure this uses theme colors internally
          const SizedBox(height: 24),

          _buildSectionTitle('Appearance'),
          _buildThemeToggleCard(
            settingsProvider,
            theme,
            isDarkMode,
          ), // Ensure this uses theme colors internally
          const SizedBox(height: 16),
          _buildColorSelectionCard(
            settingsProvider,
            theme,
          ), // Ensure this uses theme colors internally
          const SizedBox(height: 24),

          _buildSectionTitle('Account'),
          _buildAccountActionCard(
            // Ensure this uses theme colors internally
            context,
            icon: Ionicons.log_out_outline,
            title: 'Logout',
            subtitle: 'Sign out from your account',
            color: Colors.red.shade400,
            onTap: () {
              _showLogoutConfirmation(context);
            },
          ),
          // Add more settings sections/cards as needed (e.g., Notifications, Privacy)
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildUserInfoCard(ThemeData theme) {
    return Card(
      // Card implicitly uses theme.cardColor
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              child: Icon(
                Ionicons.person_circle_outline,
                size: 32,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _userName ?? 'Admin User', // Display name or placeholder
                    style: GoogleFonts.outfit(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      // color: theme.textTheme.bodyLarge?.color, // Handled by theme
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userEmail ??
                        'No email found', // Display email or placeholder
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            // Optional: Edit profile button
            // IconButton(
            //   icon: Icon(Ionicons.create_outline, color: Colors.grey.shade500),
            //   onPressed: () { /* Navigate to edit profile */ },
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeToggleCard(
    SettingsProvider settingsProvider,
    ThemeData theme,
    bool isDarkMode,
  ) {
    return Card(
      // Card implicitly uses theme.cardColor
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 8.0,
        ),
        title: Text(
          'Dark Mode',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w500,
            // color: theme.textTheme.bodyLarge?.color, // Handled by theme
          ),
        ),
        subtitle: Text(
          isDarkMode ? 'Enabled' : 'Disabled',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
          ),
        ),
        value: isDarkMode,
        onChanged: (value) {
          settingsProvider.setThemeMode(
            value ? ThemeMode.dark : ThemeMode.light,
          );
        },
        secondary: Icon(
          isDarkMode ? Ionicons.moon_outline : Ionicons.sunny_outline,
          color: theme.colorScheme.primary,
        ),
        activeColor:
            theme.colorScheme.primary, // Color of the switch track when on
        inactiveThumbColor: Colors.grey.shade400, // Visible thumb in light mode
        inactiveTrackColor: Colors.grey.shade300, // Visible track in light mode
      ),
    );
  }

  Widget _buildColorSelectionCard(
    SettingsProvider settingsProvider,
    ThemeData theme,
  ) {
    return Card(
      // Card implicitly uses theme.cardColor
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'App Primary Color',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w500,
                fontSize: 16,
                // color: theme.textTheme.bodyLarge?.color, // Handled by theme
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12.0,
              runSpacing: 12.0,
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
                            ? (theme.brightness == Brightness.dark
                                  ? Colors.white70
                                  : Colors.black87)
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
                            color: theme.brightness == Brightness.dark
                                ? Colors.black
                                : Colors.white,
                            size: 20,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Card(
      // Card implicitly uses theme.cardColor
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 10.0,
        ),
        leading: Icon(icon, color: color, size: 26),
        title: Text(
          title,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w500, color: color),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
          ),
        ),
        trailing: Icon(
          Ionicons.chevron_forward_outline,
          size: 18,
          color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
        ),
        onTap: onTap,
      ),
    );
  }

  // Simple confirmation dialog for logout
  Future<void> _showLogoutConfirmation(BuildContext context) async {
    final theme = Theme.of(context);
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text('Confirm Logout'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[Text('Are you sure you want to log out?')],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red.shade400),
              child: const Text('Logout'),
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Close the dialog
                // Perform actual logout
                await _storage.deleteAll(); // Clear all secure storage
                if (mounted) {
                  // Navigate to login screen and remove all previous routes
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (Route<dynamic> route) => false,
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}
