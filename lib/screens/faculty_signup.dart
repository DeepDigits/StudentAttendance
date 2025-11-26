import 'package:flutter/material.dart';
import 'package:attendance_tracking/config/api_config.dart';
import 'package:attendance_tracking/utils/snackbar_utils.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ionicons/ionicons.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter/services.dart';

class FacultySignupPage extends StatefulWidget {
  const FacultySignupPage({super.key});

  @override
  State<FacultySignupPage> createState() => _FacultySignupPageState();
}

class _FacultySignupPageState extends State<FacultySignupPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _phoneController = TextEditingController();
  final _qualificationsController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  File? _selectedProfilePic;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;

  String? _selectedDepartment;

  final List<String> _departments = ['BCA', 'BSc', 'BCom', 'Electronics'];

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedProfilePic = File(pickedFile.path);
        });
      } else {
        Fluttertoast.showToast(msg: "No image selected");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error picking image: $e");
    }
  }

  Future<void> _signupFaculty() async {
    final bool isValid = _formKey.currentState!.validate();

    setState(() {});

    if (!isValid || _selectedDepartment == null) {
      if (_selectedDepartment == null)
        ToastUtils.showErrorToast('Please select a department.');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      ToastUtils.showErrorToast('Passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final Uri url = Uri.parse('${ApiConfig.baseUrl}/api/register/faculty/');

    var request = http.MultipartRequest('POST', url);

    request.fields['name'] = _nameController.text.trim();
    request.fields['email'] = _emailController.text.trim();
    request.fields['password'] = _passwordController.text;
    request.fields['employee_id'] = _employeeIdController.text.trim();
    request.fields['department'] = _selectedDepartment!;
    request.fields['phone'] = _phoneController.text.trim();
    request.fields['qualifications'] = _qualificationsController.text.trim();

    if (_selectedProfilePic != null) {
      try {
        String fileName = _selectedProfilePic!.path.split('/').last;
        String fileExtension = fileName.split('.').last.toLowerCase();
        MediaType? contentType;

        if (fileExtension == 'jpg' || fileExtension == 'jpeg') {
          contentType = MediaType('image', 'jpeg');
        } else if (fileExtension == 'png') {
          contentType = MediaType('image', 'png');
        }

        if (contentType != null) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'profile_pic',
              _selectedProfilePic!.path,
              contentType: contentType,
              filename: fileName,
            ),
          );
        } else {
          print("Unsupported image type: $fileExtension");
          ToastUtils.showErrorToast('Unsupported image type selected.');
          setState(() => _isLoading = false);
          return;
        }
      } catch (e) {
        print("Error adding image file: $e");
        ToastUtils.showErrorToast('Error attaching image.');
        setState(() => _isLoading = false);
        return;
      }
    }

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      final data = json.decode(response.body);

      if (!mounted) return;

      if (response.statusCode == 201) {
        ToastUtils.showSuccessToast(
          data['message'] ?? 'Faculty registered successfully! Please log in.',
        );
        if (Navigator.canPop(context)) Navigator.pop(context);
      } else {
        ToastUtils.showErrorToast(
          data['error'] ?? 'Registration failed. Please try again.',
        );
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showErrorToast('Error connecting to server: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Ionicons.arrow_back, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Beautiful Icon
              Center(
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: primaryColor.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Ionicons.school_outline,
                    size: 34,
                    color: primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Faculty Registration',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create your faculty profile',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: subtleTextColor,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade100,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark
                                      ? Colors.grey.shade700
                                      : Colors.grey.shade300,
                                  width: 2,
                                ),
                                image: _selectedProfilePic != null
                                    ? DecorationImage(
                                        image: FileImage(_selectedProfilePic!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: _selectedProfilePic == null
                                  ? Icon(
                                      Ionicons.camera_outline,
                                      size: 32,
                                      color: subtleTextColor,
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _selectedProfilePic == null
                                ? "Add Profile Picture (Optional)"
                                : "Change Profile Picture",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: subtleTextColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildFormFieldLabel('Full Name', textColor),
                    TextFormField(
                      controller: _nameController,
                      style: TextStyle(color: textColor),
                      decoration: _buildInputDecoration(
                        context: context,
                        hintText: 'Enter Full Name',
                        icon: Ionicons.person_outline,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter name';
                        }
                        if (RegExp(r'[0-9]').hasMatch(value)) {
                          return 'Name cannot contain numbers';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildFormFieldLabel('Email', textColor),
                    TextFormField(
                      controller: _emailController,
                      style: TextStyle(color: textColor),
                      decoration: _buildInputDecoration(
                        context: context,
                        hintText: 'Enter Email',
                        icon: Ionicons.mail_outline,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter email';
                        }
                        final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                        if (!emailRegex.hasMatch(value.trim())) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildFormFieldLabel('Employee ID', textColor),
                    TextFormField(
                      controller: _employeeIdController,
                      style: TextStyle(color: textColor),
                      decoration: _buildInputDecoration(
                        context: context,
                        hintText: 'Enter Employee ID',
                        icon: Ionicons.id_card_outline,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter employee ID';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildFormFieldLabel('Department', textColor),
                    DropdownButtonFormField<String>(
                      value: _selectedDepartment,
                      style: GoogleFonts.inter(color: textColor, fontSize: 15),
                      dropdownColor: isDark
                          ? Colors.grey.shade800
                          : Colors.white,
                      items: _departments.map((String department) {
                        return DropdownMenuItem<String>(
                          value: department,
                          child: Text(
                            department,
                            style: GoogleFonts.inter(fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedDepartment = newValue;
                        });
                      },
                      decoration:
                          _buildInputDecoration(
                            context: context,
                            hintText: 'Select Department',
                            icon: Ionicons.briefcase_outline,
                          ).copyWith(
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 0,
                            ),
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(
                                left: 16.0,
                                right: 12.0,
                              ),
                              child: Icon(
                                Ionicons.briefcase_outline,
                                color: subtleTextColor,
                                size: 20,
                              ),
                            ),
                          ),
                      validator: (value) =>
                          value == null ? 'Please select a department' : null,
                      isExpanded: true,
                      icon: Icon(
                        Ionicons.chevron_down_outline,
                        color: subtleTextColor,
                        size: 20,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    const SizedBox(height: 12),
                    _buildFormFieldLabel('Phone Number', textColor),
                    TextFormField(
                      controller: _phoneController,
                      style: TextStyle(color: textColor),
                      decoration: _buildInputDecoration(
                        context: context,
                        hintText: 'Enter Phone Number',
                        icon: Ionicons.call_outline,
                      ),
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter phone number';
                        }
                        final phoneRegex = RegExp(r'^\+?[0-9]{10,}$');
                        if (!phoneRegex.hasMatch(value.trim())) {
                          return 'Please enter a valid phone number (min 10 digits)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildFormFieldLabel('Qualifications', textColor),
                    TextFormField(
                      controller: _qualificationsController,
                      style: TextStyle(color: textColor),
                      decoration: _buildInputDecoration(
                        context: context,
                        hintText: 'Enter Qualifications (e.g., M.Tech, Ph.D.)',
                        icon: Ionicons.ribbon_outline,
                      ),
                      maxLines: 2,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter qualifications';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildFormFieldLabel('Password', textColor),
                    TextFormField(
                      controller: _passwordController,
                      style: TextStyle(color: textColor),
                      obscureText: _obscurePassword,
                      decoration:
                          _buildInputDecoration(
                            context: context,
                            hintText: '.........',
                            icon: Ionicons.lock_closed_outline,
                          ).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Ionicons.eye_off_outline
                                    : Ionicons.eye_outline,
                                color: subtleTextColor,
                                size: 22,
                              ),
                              onPressed: () => setState(() {
                                _obscurePassword = !_obscurePassword;
                              }),
                            ),
                          ),
                      validator: (value) {
                        if (value?.isEmpty ?? true)
                          return 'Please enter a password';
                        if (value!.length < 6)
                          return 'Password must be at least 6 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildFormFieldLabel('Confirm Password', textColor),
                    TextFormField(
                      controller: _confirmPasswordController,
                      style: TextStyle(color: textColor),
                      obscureText: _obscureConfirmPassword,
                      decoration:
                          _buildInputDecoration(
                            context: context,
                            hintText: '.........',
                            icon: Ionicons.lock_closed_outline,
                          ).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Ionicons.eye_off_outline
                                    : Ionicons.eye_outline,
                                color: subtleTextColor,
                                size: 22,
                              ),
                              onPressed: () => setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              }),
                            ),
                          ),
                      validator: (value) {
                        if (value?.isEmpty ?? true)
                          return 'Please confirm your password';
                        if (value != _passwordController.text)
                          return 'Passwords do not match';
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signupFaculty,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
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
                                'Register as Faculty',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
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
                            onTap: () {
                              if (Navigator.canPop(context))
                                Navigator.pop(context);
                            },
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
                                      text: "Already have an account? ",
                                      style: TextStyle(color: subtleTextColor),
                                    ),
                                    TextSpan(
                                      text: 'Sign In',
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

  Widget _buildFormFieldLabel(String label, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required BuildContext context,
    required String hintText,
    IconData? icon,
  }) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color primaryColor = theme.colorScheme.primary;
    final Color subtleTextColor = isDark
        ? Colors.grey.shade400
        : Colors.grey.shade600;
    final Color borderColor = isDark
        ? Colors.grey.shade700
        : Colors.grey.shade300;
    final Color fillColor = isDark ? Colors.grey.shade900 : Colors.grey.shade50;

    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.inter(
        color: theme.hintColor.withOpacity(0.6),
        fontSize: 14,
      ),
      prefixIcon: icon != null
          ? Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 12.0),
              child: Icon(icon, color: subtleTextColor, size: 20),
            )
          : null,
      prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
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
        borderSide: BorderSide(color: primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.red.shade400),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _employeeIdController.dispose();
    _phoneController.dispose();
    _qualificationsController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
