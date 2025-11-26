// Faculty Settings Screen - View and edit faculty profile settings
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ionicons/ionicons.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:attendance_tracking/providers/settings_provider.dart';
import 'package:attendance_tracking/config/api_config.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class FacultySettingsScreen extends StatefulWidget {
  final String? profileId;
  final Map<String, dynamic>? initialData;

  const FacultySettingsScreen({super.key, this.profileId, this.initialData});

  @override
  State<FacultySettingsScreen> createState() => _FacultySettingsScreenState();
}

class _FacultySettingsScreenState extends State<FacultySettingsScreen> {
  Map<String, dynamic> _profileData = {};
  bool _isLoading = true;
  bool _isSaving = false;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  // Controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _qualificationsController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _profileData = widget.initialData!;
      _populateFields();
      _isLoading = false;
    } else {
      _loadProfileData();
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _qualificationsController.dispose();
    super.dispose();
  }

  void _populateFields() {
    _firstNameController.text = _profileData['first_name'] ?? '';
    _lastNameController.text = _profileData['last_name'] ?? '';
    _emailController.text = _profileData['email'] ?? '';
    _phoneController.text = _profileData['phone'] ?? '';
    _qualificationsController.text = _profileData['qualifications'] ?? '';
  }

  Future<void> _loadProfileData() async {
    if (widget.profileId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final url = '${ApiConfig.baseUrl}/api/faculty/${widget.profileId}/';

      final response = await http
          .get(Uri.parse(url), headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        setState(() {
          _profileData = json.decode(response.body);
          _populateFields();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading profile: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      Fluttertoast.showToast(
        msg: 'Error selecting image',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _saveProfile() async {
    if (_firstNameController.text.trim().isEmpty) {
      Fluttertoast.showToast(
        msg: 'First name is required',
        backgroundColor: Colors.orange,
      );
      return;
    }

    if (_lastNameController.text.trim().isEmpty) {
      Fluttertoast.showToast(
        msg: 'Last name is required',
        backgroundColor: Colors.orange,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final url =
          '${ApiConfig.baseUrl}/api/faculty/${widget.profileId}/update/';

      var request = http.MultipartRequest('PUT', Uri.parse(url));

      request.fields['first_name'] = _firstNameController.text.trim();
      request.fields['last_name'] = _lastNameController.text.trim();
      request.fields['phone'] = _phoneController.text.trim();
      request.fields['qualifications'] = _qualificationsController.text.trim();

      if (_selectedImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'profile_pic',
            _selectedImage!.path,
          ),
        );
      }

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        Fluttertoast.showToast(
          msg: 'Profile updated successfully!',
          backgroundColor: Colors.green,
        );
        _loadProfileData();
      } else {
        final error = json.decode(response.body);
        Fluttertoast.showToast(
          msg: error['error'] ?? 'Failed to update profile',
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      print('Error saving profile: $e');
      Fluttertoast.showToast(
        msg: 'Error updating profile',
        backgroundColor: Colors.red,
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    // Use purple theme for faculty
    const MaterialColor primaryColor = Colors.purple;
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Center(
        child: SpinKitFadingCircle(color: primaryColor, size: 50.0),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Profile Picture Section
          Center(
            child: Stack(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    image: _selectedImage != null
                        ? DecorationImage(
                            image: FileImage(_selectedImage!),
                            fit: BoxFit.cover,
                          )
                        : (_profileData['profile_pic_url'] != null &&
                              _profileData['profile_pic_url']
                                  .toString()
                                  .isNotEmpty)
                        ? DecorationImage(
                            image: NetworkImage(
                              _profileData['profile_pic_url'],
                            ),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child:
                      _selectedImage == null &&
                          (_profileData['profile_pic_url'] == null ||
                              _profileData['profile_pic_url']
                                  .toString()
                                  .isEmpty)
                      ? Icon(
                          Ionicons.person,
                          size: 50,
                          color: isDark ? Colors.grey[600] : Colors.grey[400],
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Ionicons.camera,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Employee ID (Read-only)
          _buildInfoCard(
            'Employee ID',
            _profileData['employee_id'] ?? 'N/A',
            Ionicons.id_card_outline,
            primaryColor,
            isDark,
          ),
          const SizedBox(height: 12),

          // Department (Read-only)
          _buildInfoCard(
            'Department',
            _profileData['department'] ?? 'N/A',
            Ionicons.business_outline,
            primaryColor,
            isDark,
          ),
          const SizedBox(height: 24),

          // Editable Fields
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Personal Information',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),

                // First Name
                _buildTextField(
                  controller: _firstNameController,
                  label: 'First Name',
                  icon: Ionicons.person_outline,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),

                // Last Name
                _buildTextField(
                  controller: _lastNameController,
                  label: 'Last Name',
                  icon: Ionicons.person_outline,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),

                // Email (Read-only)
                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Ionicons.mail_outline,
                  isDark: isDark,
                  readOnly: true,
                ),
                const SizedBox(height: 16),

                // Phone
                _buildTextField(
                  controller: _phoneController,
                  label: 'Phone',
                  icon: Ionicons.call_outline,
                  isDark: isDark,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),

                // Qualifications
                _buildTextField(
                  controller: _qualificationsController,
                  label: 'Qualifications',
                  icon: Ionicons.school_outline,
                  isDark: isDark,
                  maxLines: 3,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: primaryColor.withOpacity(0.5),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Save Changes',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),

          // App Settings Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'App Settings',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),

                // Theme Toggle
                _buildSettingsTile(
                  title: 'Dark Mode',
                  subtitle: 'Enable dark theme',
                  icon: Ionicons.moon_outline,
                  isDark: isDark,
                  trailing: Switch(
                    value: isDark,
                    onChanged: (value) {
                      settingsProvider.setThemeMode(
                        value ? ThemeMode.dark : ThemeMode.light,
                      );
                    },
                    activeColor: primaryColor,
                  ),
                ),
                const Divider(),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Logout Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showLogoutDialog(context, primaryColor, isDark),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Ionicons.log_out_outline),
              label: Text(
                'Logout',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    String label,
    String value,
    IconData icon,
    Color primaryColor,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: primaryColor, size: 22),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    bool readOnly = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(
          color: isDark ? Colors.grey[500] : Colors.grey[600],
        ),
        prefixIcon: Icon(
          icon,
          color: isDark ? Colors.grey[500] : Colors.grey[400],
        ),
        filled: true,
        fillColor: readOnly
            ? (isDark ? Colors.grey[900] : Colors.grey[100])
            : (isDark ? Colors.grey[800] : Colors.grey[50]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: readOnly ? Colors.grey : Theme.of(context).primaryColor,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
      style: GoogleFonts.inter(
        color: readOnly
            ? (isDark ? Colors.grey[500] : Colors.grey[600])
            : (isDark ? Colors.white : Colors.black87),
      ),
    );
  }

  Widget _buildSettingsTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isDark,
    required Widget trailing,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: isDark ? Colors.grey[400] : Colors.grey[600]),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: isDark ? Colors.grey[500] : Colors.grey[600],
        ),
      ),
      trailing: trailing,
    );
  }

  void _showLogoutDialog(
    BuildContext context,
    Color primaryColor,
    bool isDark,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Logout',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.inter(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Clear storage and navigate to login
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/login', (route) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Logout',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
