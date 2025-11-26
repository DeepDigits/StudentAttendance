// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:attendance_tracking/screens/signup_page.dart';
import 'package:attendance_tracking/config/api_config.dart';
// import 'package:attendance_tracking/screens/worker/worker_dashboard.dart';
import 'package:attendance_tracking/utils/snackbar_utils.dart';
import 'package:attendance_tracking/screens/admin/dashboard.dart';
// Placeholder imports for other dashboards - CREATE THESE FILES LATER
// import 'package:attendance_tracking/screens/worker/worker_dashboard.dart';
// import 'package:attendance_tracking/screens/contractor/contractor_dashboard.dart';
import 'package:attendance_tracking/screens/user/user_dashboard.dart'; // Import UserDashboard
import 'package:attendance_tracking/screens/faculty/faculty_dashboard.dart'; // Import FacultyDashboard
import 'package:attendance_tracking/screens/faculty_signup.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:ionicons/ionicons.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:attendance_tracking/providers/settings_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _isLoading = false;

  // Create storage instance
  final _storage = const FlutterSecureStorage();

  // Keys for FlutterSecureStorage
  static const String _storageEmailKey = 'saved_email';
  static const String _storageRememberKey = 'remember_me';
  static const String _storageUserTypeKey =
      'user_type'; // Key to store user type

  @override
  void initState() {
    super.initState();
    _loadCredentials();
  }

  // Load saved email and remember me status from secure storage
  void _loadCredentials() async {
    try {
      final String? email = await _storage.read(key: _storageEmailKey);
      final String? rememberMeStr = await _storage.read(
        key: _storageRememberKey,
      );

      if (rememberMeStr == 'true' && email != null) {
        setState(() {
          _emailController.text = email;
          _rememberMe = true;
        });
      }
    } catch (e) {
      print("Error loading from secure storage: $e");
    }
  }

  // Save or clear credentials in secure storage
  Future<void> _handleRememberMe(
    bool remember,
    String email,
    String? userType,
    String? userId,
  ) async {
    try {
      if (remember) {
        await _storage.write(key: _storageEmailKey, value: email);
        await _storage.write(key: _storageRememberKey, value: 'true');
        if (userType != null) {
          await _storage.write(
            key: _storageUserTypeKey,
            value: userType,
          ); // Save user type
        }
        if (userId != null) {
          await _storage.write(key: 'user_id', value: userId); // Save user ID
        }
      } else {
        await _storage.delete(key: _storageEmailKey);
        await _storage.delete(key: _storageRememberKey);
        await _storage.delete(key: _storageUserTypeKey); // Clear user type
        await _storage.delete(key: 'user_id'); // Clear user ID
      }
    } catch (e) {
      print("Error saving to secure storage: $e");
    }
  }

  Future<void> _loginUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      final String email = _emailController.text.trim();
      final String password = _passwordController.text;

      try {
        final response = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/api/login/'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: json.encode({'email': email, 'password': password}),
        );
        if (!mounted) return;
        final data = json.decode(response.body);

        if (response.statusCode == 200 && data.containsKey('user')) {
          final userMap = data['user'] as Map<String, dynamic>;
          final String? userType = userMap['userType']; // Get user type
          final String userId = userMap['id']?.toString() ?? ''; // Get user ID

          await _handleRememberMe(
            _rememberMe,
            email,
            userType,
            userId,
          ); // Pass userType and userId to save

          // Navigate based on userType
          switch (userType) {
            case 'admin':
              ToastUtils.showSuccessToast('Welcome Admin!');
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AdminDashboard()),
              );
              break;
            case 'faculty':
              print(
                'Faculty login - profileId: ${userMap['profileId']}, department: ${userMap['department']}',
              ); // Debug
              ToastUtils.showSuccessToast('Welcome Faculty!');
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => FacultyDashboard(
                    userName: userMap['fullName'] ?? 'Faculty',
                    userEmail: userMap['email'] ?? '',
                    userId: userId,
                    department: userMap['department'] ?? '',
                    profileId: userMap['profileId']?.toString() ?? '',
                  ),
                ),
              );
              break;
            case 'student':
            case 'staff':
              ToastUtils.showSuccessToast('Welcome to Attendance System!');
              // TODO: Replace with actual Student/Staff Dashboard navigation
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => UserDashboard(
                    userName: userMap['fullName'],
                    userEmail: userMap['email'],
                    userId: userId,
                  ),
                ),
              );
              break;
            case 'user':
            default: // Handle 'user' or any unexpected type
              ToastUtils.showSuccessToast('Login successful!');
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => UserDashboard(
                    userName: userMap['fullName'],
                    userEmail: userMap['email'],
                    userId: userId,
                  ),
                ), // Navigate to UserDashboard
              );
              break;
          }
        } else {
          ToastUtils.showErrorToast(
            data['error'] ?? 'Invalid email or password',
          );
        }
      } catch (e) {
        if (mounted) {
          ToastUtils.showErrorToast('Error: $e');
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  // --- Dialog to Choose Signup Type ---
  void _showSignupOptionsDialog(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final Color primaryColor = theme.colorScheme.primary;
    final Color headerForegroundColor = theme.colorScheme.onPrimary;

    final Color gradientStart = isDark ? Colors.grey.shade800 : Colors.white;
    final Color gradientEnd = isDark
        ? Colors.grey.shade900
        : Colors.grey.shade50;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [gradientStart, gradientEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.5)
                      : Colors.grey.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- Custom Header ---
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                    decoration: BoxDecoration(color: primaryColor),
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
                            'Register As',
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
                          tooltip: 'Cancel',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  // --- Options Content ---
                  Flexible(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // --- Student/Staff Option ---
                            // _buildDialogOption(
                            //   context: context,
                            //   icon: Ionicons.person_outline,
                            //   text: 'Register as Student',
                            //   color: primaryColor,
                            //   onTap: () {
                            //     Navigator.pop(context);
                            //     Navigator.push(
                            //       context,
                            //       MaterialPageRoute(
                            //         builder: (context) => const SignupPage(),
                            //       ),
                            //     );
                            //   },
                            // ),
                            Divider(
                              height: 1,
                              indent: 20,
                              endIndent: 20,
                              color: isDark
                                  ? Colors.grey[800]
                                  : Colors.grey[200],
                            ),
                            // --- Faculty Option ---
                            _buildDialogOption(
                              context: context,
                              icon: Ionicons.school_outline,
                              text: 'Register as Faculty',
                              color: primaryColor,
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const FacultySignupPage(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper for dialog options - Modified to respect theme
  Widget _buildDialogOption({
    required BuildContext context,
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  text,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: isDark ? Colors.grey.shade200 : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
    final Color borderColor = isDark
        ? Colors.grey.shade700
        : Colors.grey.shade300;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              // --- Beautiful Logo/Icon ---
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: primaryColor.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Ionicons.clipboard_outline,
                    size: 40,
                    color: primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // --- Welcome Text ---
              Text(
                'Welcome Back!',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Smart Attendance System using Facial Recognition',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: subtleTextColor,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 44),

              // --- Form ---
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Email Field ---
                    Text(
                      'Email Or User Name',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        hintText: 'Enter your Email here',
                        hintStyle: GoogleFonts.inter(
                          color: theme.hintColor.withOpacity(0.6),
                          fontSize: 14,
                        ),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 16, right: 12),
                          child: Icon(
                            Ionicons.mail_outline,
                            color: subtleTextColor,
                            size: 20,
                          ),
                        ),
                        filled: true,
                        fillColor: isDark
                            ? Colors.grey.shade900
                            : Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 20,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: primaryColor,
                            width: 1.5,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.red.shade400),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: Colors.red.shade400,
                            width: 1.5,
                          ),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      style: GoogleFonts.inter(color: textColor, fontSize: 15),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value!)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 22),

                    // --- Password Field ---
                    Text(
                      'Password',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: GoogleFonts.inter(color: textColor, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        hintStyle: GoogleFonts.inter(
                          color: theme.hintColor.withOpacity(0.6),
                          fontSize: 16,
                          letterSpacing: 3,
                        ),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 16, right: 12),
                          child: Icon(
                            Ionicons.lock_closed_outline,
                            color: subtleTextColor,
                            size: 20,
                          ),
                        ),
                        suffixIcon: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Ionicons.eye_off_outline
                                  : Ionicons.eye_outline,
                              color: subtleTextColor,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        filled: true,
                        fillColor: isDark
                            ? Colors.grey.shade900
                            : Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 20,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: primaryColor,
                            width: 1.5,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.red.shade400),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: Colors.red.shade400,
                            width: 1.5,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    // --- Remember Me & Forgot Password ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              height: 22.0,
                              width: 22.0,
                              child: Checkbox(
                                value: _rememberMe,
                                onChanged: (bool? value) {
                                  setState(() {
                                    _rememberMe = value ?? false;
                                  });
                                },
                                activeColor: primaryColor,
                                side: BorderSide(
                                  color: subtleTextColor,
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Remember me',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: subtleTextColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Forgot Password not implemented yet.',
                                ),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: primaryColor,
                            padding: EdgeInsets.zero,
                            minimumSize: Size(50, 30),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Forgot Password?',
                            style: GoogleFonts.inter(
                              color: primaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 36),

                    // --- Sign In Button ---
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _loginUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                          shadowColor: primaryColor.withOpacity(0.3),
                          disabledBackgroundColor: primaryColor.withOpacity(
                            0.6,
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                'Sign in',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // --- Sign Up Link ---
                    Center(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: primaryColor.withOpacity(0.3),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _showSignupOptionsDialog(context),
                            borderRadius: BorderRadius.circular(14),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical: 14,
                              ),
                              child: RichText(
                                text: TextSpan(
                                  style: GoogleFonts.inter(fontSize: 14),
                                  children: [
                                    TextSpan(
                                      text: "Don't have an account? ",
                                      style: TextStyle(color: subtleTextColor),
                                    ),
                                    TextSpan(
                                      text: 'Register Here',
                                      style: TextStyle(
                                        color: primaryColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
