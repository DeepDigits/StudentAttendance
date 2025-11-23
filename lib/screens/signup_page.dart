import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:attendance_tracking/config/api_config.dart';
import 'package:attendance_tracking/utils/snackbar_utils.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';
import 'package:attendance_tracking/providers/settings_provider.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Student-specific fields
  final _rollNumberController = TextEditingController();
  final _departmentController = TextEditingController();
  final _yearOfStudyController = TextEditingController();
  final _sectionController = TextEditingController();
  final _phoneController = TextEditingController();

  // State for password visibility
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  Future<void> _signupUser() async {
    // Student signup logic
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ToastUtils.showErrorToast('Passwords do not match');
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final response = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/api/register/student/'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: json.encode({
            'first_name': _firstNameController.text.trim(),
            'last_name': _lastNameController.text.trim(),
            'email': _emailController.text.trim(),
            'password': _passwordController.text,
            'roll_number': _rollNumberController.text.trim(),
            'department': _departmentController.text.trim(),
            'year_of_study': _yearOfStudyController.text.trim(),
            'section': _sectionController.text.trim(),
            'phone': _phoneController.text.trim(),
          }),
        );

        if (!mounted) return;

        if (response.statusCode == 201) {
          ToastUtils.showSuccessToast(
            'Registration successful! Your account is pending approval.',
          );
          Navigator.pop(context); // Go back to login page
        } else {
          final data = json.decode(response.body);
          ToastUtils.showErrorToast(data['error'] ?? 'Failed to register');
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

  @override
  Widget build(BuildContext context) {
    // Use theme colors
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final Color primaryColor = theme.colorScheme.primary;
    final Color textColor =
        theme.textTheme.bodyLarge?.color ??
        (isDark ? Colors.white : Colors.black87);
    final Color subtleTextColor =
        theme.textTheme.bodySmall?.color ??
        (isDark ? Colors.grey.shade400 : Colors.grey.shade600);
    final Color cardColor = theme.cardColor;
    final Color borderColor = isDark
        ? Colors.grey.shade700
        : Colors.grey.shade300;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Register for Attendance System',
          style: GoogleFonts.inter(color: theme.appBarTheme.foregroundColor),
        ),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Ionicons.chevron_back,
            color: theme.appBarTheme.foregroundColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // Header Text
                Text(
                  'Join the Smart Attendance System',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Register to track your attendance using facial recognition',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: subtleTextColor,
                  ),
                ),
                const SizedBox(height: 30),

                // First Name Field
                Text(
                  'First Name',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _firstNameController,
                  decoration: InputDecoration(
                    hintText: 'Enter your first name',
                    hintStyle: GoogleFonts.inter(
                      color: theme.hintColor,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Ionicons.person_outline,
                      color: primaryColor,
                      size: 20,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? theme.inputDecorationTheme.fillColor ??
                              Colors.grey.shade800
                        : cardColor,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 15,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: primaryColor, width: 1.5),
                    ),
                  ),
                  style: TextStyle(color: textColor),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'First name is required';
                    }
                    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value.trim())) {
                      return 'First name can only contain letters and spaces';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Last Name Field
                Text(
                  'Last Name',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _lastNameController,
                  decoration: InputDecoration(
                    hintText: 'Enter your last name',
                    hintStyle: GoogleFonts.inter(
                      color: theme.hintColor,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Ionicons.person_outline,
                      color: primaryColor,
                      size: 20,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? theme.inputDecorationTheme.fillColor ??
                              Colors.grey.shade800
                        : cardColor,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 15,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: primaryColor, width: 1.5),
                    ),
                  ),
                  style: TextStyle(color: textColor),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Last name is required';
                    }
                    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value.trim())) {
                      return 'Last name can only contain letters and spaces';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Email Field
                Text(
                  'Email Address',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: 'Enter your email',
                    hintStyle: GoogleFonts.inter(
                      color: theme.hintColor,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Ionicons.mail_outline,
                      color: primaryColor,
                      size: 20,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? theme.inputDecorationTheme.fillColor ??
                              Colors.grey.shade800
                        : cardColor,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 15,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: primaryColor, width: 1.5),
                    ),
                  ),
                  style: TextStyle(color: textColor),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email is required';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Roll Number Field
                Text(
                  'Roll Number',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _rollNumberController,
                  decoration: InputDecoration(
                    hintText: 'Enter your roll number',
                    hintStyle: GoogleFonts.inter(
                      color: theme.hintColor,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Ionicons.id_card_outline,
                      color: primaryColor,
                      size: 20,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? theme.inputDecorationTheme.fillColor ??
                              Colors.grey.shade800
                        : cardColor,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 15,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: primaryColor, width: 1.5),
                    ),
                  ),
                  style: TextStyle(color: textColor),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Roll number is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Department Field
                Text(
                  'Department',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _departmentController,
                  decoration: InputDecoration(
                    hintText: 'e.g., Computer Science',
                    hintStyle: GoogleFonts.inter(
                      color: theme.hintColor,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Ionicons.business_outline,
                      color: primaryColor,
                      size: 20,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? theme.inputDecorationTheme.fillColor ??
                              Colors.grey.shade800
                        : cardColor,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 15,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: primaryColor, width: 1.5),
                    ),
                  ),
                  style: TextStyle(color: textColor),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Department is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Year of Study Field
                Text(
                  'Year of Study',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _yearOfStudyController,
                  decoration: InputDecoration(
                    hintText: 'e.g., 1st Year, 2nd Year',
                    hintStyle: GoogleFonts.inter(
                      color: theme.hintColor,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Ionicons.school_outline,
                      color: primaryColor,
                      size: 20,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? theme.inputDecorationTheme.fillColor ??
                              Colors.grey.shade800
                        : cardColor,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 15,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: primaryColor, width: 1.5),
                    ),
                  ),
                  style: TextStyle(color: textColor),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Year of study is required';
                    }
                    if (!RegExp(r'^[0-9]+$').hasMatch(value.trim())) {
                      return 'Year of study must be a number (e.g., 1, 2, 3, 4)';
                    }
                    final year = int.tryParse(value.trim());
                    if (year == null || year < 1 || year > 4) {
                      return 'Year must be between 1 and 4';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Section Field
                Text(
                  'Section',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _sectionController,
                  decoration: InputDecoration(
                    hintText: 'e.g., A, B, C',
                    hintStyle: GoogleFonts.inter(
                      color: theme.hintColor,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Ionicons.grid_outline,
                      color: primaryColor,
                      size: 20,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? theme.inputDecorationTheme.fillColor ??
                              Colors.grey.shade800
                        : cardColor,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 15,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: primaryColor, width: 1.5),
                    ),
                  ),
                  style: TextStyle(color: textColor),
                  validator: (value) {
                    // Section is optional
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Phone Number Field
                Text(
                  'Phone Number',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    hintText: 'Enter your phone number',
                    hintStyle: GoogleFonts.inter(
                      color: theme.hintColor,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Ionicons.call_outline,
                      color: primaryColor,
                      size: 20,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? theme.inputDecorationTheme.fillColor ??
                              Colors.grey.shade800
                        : cardColor,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 15,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: primaryColor, width: 1.5),
                    ),
                  ),
                  style: TextStyle(color: textColor),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Phone number is required';
                    }
                    if (!RegExp(r'^[0-9]{10}$').hasMatch(value.trim())) {
                      return 'Phone number must be exactly 10 digits';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Password Field
                Text(
                  'Password',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Create a password',
                    hintStyle: GoogleFonts.inter(
                      color: theme.hintColor,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Ionicons.lock_closed_outline,
                      color: primaryColor,
                      size: 20,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Ionicons.eye_off_outline
                            : Ionicons.eye_outline,
                        color: subtleTextColor,
                        size: 22,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    filled: true,
                    fillColor: isDark
                        ? theme.inputDecorationTheme.fillColor ??
                              Colors.grey.shade800
                        : cardColor,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 15,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: primaryColor, width: 1.5),
                    ),
                  ),
                  style: TextStyle(color: textColor),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Password is required';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Confirm Password Field
                Text(
                  'Confirm Password',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    hintText: 'Confirm your password',
                    hintStyle: GoogleFonts.inter(
                      color: theme.hintColor,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Ionicons.lock_closed_outline,
                      color: primaryColor,
                      size: 20,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Ionicons.eye_off_outline
                            : Ionicons.eye_outline,
                        color: subtleTextColor,
                        size: 22,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    filled: true,
                    fillColor: isDark
                        ? theme.inputDecorationTheme.fillColor ??
                              Colors.grey.shade800
                        : cardColor,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 15,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: primaryColor, width: 1.5),
                    ),
                  ),
                  style: TextStyle(color: textColor),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),

                // Sign Up Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signupUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 2,
                      disabledBackgroundColor: theme.disabledColor,
                      disabledForegroundColor: isDark
                          ? Colors.grey.shade700
                          : Colors.grey.shade300,
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.onPrimary,
                              ),
                            ),
                          )
                        : Text(
                            'Sign Up',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: theme
                                  .colorScheme
                                  .onPrimary, // Ensure white text in dark mode
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 25),

                // Back to Login Link
                Align(
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.inter(fontSize: 14),
                        children: [
                          TextSpan(
                            text: 'Already have an account? ',
                            style: TextStyle(color: subtleTextColor),
                          ),
                          TextSpan(
                            text: 'Log in',
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
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _rollNumberController.dispose();
    _departmentController.dispose();
    _yearOfStudyController.dispose();
    _sectionController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
