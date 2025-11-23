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
import 'package:provider/provider.dart';
import 'package:attendance_tracking/providers/settings_provider.dart';

class WorkerSignupPage extends StatefulWidget {
  const WorkerSignupPage({super.key});

  @override
  State<WorkerSignupPage> createState() => _WorkerSignupPageState();
}

class _WorkerSignupPageState extends State<WorkerSignupPage> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _adhaarController = TextEditingController();
  final _addressController = TextEditingController();
  final _skillController = TextEditingController();
  final _experienceController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  File? _selectedProfilePic;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;

  String? _selectedDistrict;

  final List<String> _keralaDistricts = [
    'Thiruvananthapuram',
    'Kollam',
    'Pathanamthitta',
    'Alappuzha',
    'Kottayam',
    'Idukki',
    'Ernakulam',
    'Thrissur',
    'Palakkad',
    'Malappuram',
    'Kozhikode',
    'Wayanad',
    'Kannur',
    'Kasaragod',
  ];

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

  Future<void> _signupWorker() async {
    final bool isValid = _formKey.currentState!.validate();

    setState(() {});

    if (!isValid) {
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ToastUtils.showErrorToast('Passwords do not match');
      return;
    }

    if (_selectedDistrict == null) {
      ToastUtils.showErrorToast('Please select a district.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final Uri url = Uri.parse('${ApiConfig.baseUrl}/api/register/worker/');

    var request = http.MultipartRequest('POST', url);

    request.fields['first_name'] = _firstNameController.text.trim();
    request.fields['last_name'] = _lastNameController.text.trim();
    request.fields['email'] = _emailController.text.trim();
    request.fields['password'] = _passwordController.text;
    request.fields['phone'] = _phoneController.text.trim();
    request.fields['adhaar'] = _adhaarController.text.trim();
    request.fields['address'] = _addressController.text.trim();
    request.fields['district'] = _selectedDistrict!;
    request.fields['hourly_rate'] = _hourlyRateController.text.trim();
    if (_skillController.text.trim().isNotEmpty) {
      request.fields['skills'] = _skillController.text.trim();
    }
    if (_experienceController.text.trim().isNotEmpty) {
      request.fields['experience'] = _experienceController.text.trim();
    }

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
        }
      } catch (e) {
        print("Error adding image file: $e");
        ToastUtils.showErrorToast('Error attaching image.');
        setState(() {
          _isLoading = false;
        });
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
          data['message'] ?? 'Worker registered successfully! Please log in.',
        );
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
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
    final Color cardColor = theme.cardColor;
    final Color borderColor = isDark
        ? Colors.grey.shade700
        : Colors.grey.shade300;
    final Color formFieldBgColor = isDark
        ? Colors.grey.shade800.withOpacity(0.3)
        : Colors.white;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor:
            theme.appBarTheme.backgroundColor ?? Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Ionicons.arrow_back,
            color: theme.appBarTheme.iconTheme?.color ?? primaryColor,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.network(
                'https://icon-library.com/images/worker-icon/worker-icon-13.jpg',
                height: 50,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Ionicons.person_add_outline,
                    size: 50,
                    color: primaryColor,
                  );
                },
              ),
              const SizedBox(height: 15),
              Text(
                'Worker Registration',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create your worker profile',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14, color: subtleTextColor),
              ),
              const SizedBox(height: 25),
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
                            child: CircleAvatar(
                              radius: 40,
                              backgroundColor: isDark
                                  ? primaryColor.withOpacity(0.2)
                                  : Colors.grey.shade200,
                              backgroundImage: _selectedProfilePic != null
                                  ? FileImage(_selectedProfilePic!)
                                  : null,
                              child: _selectedProfilePic == null
                                  ? Icon(
                                      Ionicons.camera_outline,
                                      size: 30,
                                      color: isDark
                                          ? primaryColor.withOpacity(0.7)
                                          : Colors.grey.shade500,
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _selectedProfilePic == null
                                ? "Add Profile Picture"
                                : "Change Profile Picture",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: subtleTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildFormFieldLabel('First Name', textColor),
                    TextFormField(
                      controller: _firstNameController,
                      style: TextStyle(color: textColor),
                      decoration: _buildInputDecoration(
                        context: context,
                        hintText: 'Enter First Name',
                        icon: Ionicons.person_outline,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter first name';
                        }
                        if (RegExp(r'[0-9]').hasMatch(value)) {
                          return 'Name cannot contain numbers';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildFormFieldLabel('Last Name', textColor),
                    TextFormField(
                      controller: _lastNameController,
                      style: TextStyle(color: textColor),
                      decoration: _buildInputDecoration(
                        context: context,
                        hintText: 'Enter Last Name',
                        icon: null,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter last name';
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
                    _buildFormFieldLabel('Phone', textColor),
                    TextFormField(
                      controller: _phoneController,
                      style: TextStyle(color: textColor),
                      decoration: _buildInputDecoration(
                        context: context,
                        hintText: 'Enter Phone Number',
                        icon: Ionicons.call_outline,
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter phone number';
                        }
                        final phoneRegex = RegExp(r'^\+?[0-9]{10,}$');
                        if (!phoneRegex.hasMatch(value.trim())) {
                          return 'Please enter a valid phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildFormFieldLabel('Aadhaar Number', textColor),
                    TextFormField(
                      controller: _adhaarController,
                      style: TextStyle(color: textColor),
                      decoration: _buildInputDecoration(
                        context: context,
                        hintText: 'Enter Aadhaar Number',
                        icon: Ionicons.shield_checkmark_outline,
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter Aadhaar number';
                        }
                        final aadhaarRegex = RegExp(r'^[0-9]{12}$');
                        if (!aadhaarRegex.hasMatch(value.trim())) {
                          return 'Aadhaar number must be 12 digits';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildFormFieldLabel('Address', textColor),
                    TextFormField(
                      controller: _addressController,
                      style: TextStyle(color: textColor),
                      decoration: _buildInputDecoration(
                        context: context,
                        hintText: 'Enter Address',
                        icon: Ionicons.home_outline,
                      ),
                      maxLines: 2,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildFormFieldLabel('District', textColor),
                    DropdownButtonFormField<String>(
                      value: _selectedDistrict,
                      style: TextStyle(color: textColor),
                      dropdownColor: isDark
                          ? Colors.grey.shade800
                          : Colors.white,
                      items: _keralaDistricts.map((String district) {
                        return DropdownMenuItem<String>(
                          value: district,
                          child: Text(
                            district,
                            style: GoogleFonts.inter(fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedDistrict = newValue;
                        });
                      },
                      decoration:
                          _buildInputDecoration(
                            context: context,
                            hintText: 'Select District',
                            icon: Ionicons.location_outline,
                          ).copyWith(
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 15,
                              horizontal: 0,
                            ),
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(
                                left: 15.0,
                                right: 10.0,
                              ),
                              child: Icon(
                                Ionicons.location_outline,
                                color: primaryColor,
                                size: 20,
                              ),
                            ),
                          ),
                      validator: (value) =>
                          value == null ? 'Please select a district' : null,
                      isExpanded: true,
                      icon: Icon(
                        Ionicons.chevron_down_outline,
                        color: theme.iconTheme.color?.withOpacity(0.7),
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    const SizedBox(height: 12),
                    _buildFormFieldLabel('Skills (Optional)', textColor),
                    TextFormField(
                      controller: _skillController,
                      style: TextStyle(color: textColor),
                      decoration: _buildInputDecoration(
                        context: context,
                        hintText: 'e.g., Plumbing, Electrical',
                        icon: Ionicons.construct_outline,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildFormFieldLabel(
                      'Experience (Years - Optional)',
                      textColor,
                    ),
                    TextFormField(
                      controller: _experienceController,
                      style: TextStyle(color: textColor),
                      decoration: _buildInputDecoration(
                        context: context,
                        hintText: 'e.g., 5 (Max 20)',
                        icon: Ionicons.briefcase_outline,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return null;
                        }
                        final int? experienceYears = int.tryParse(value.trim());
                        if (experienceYears == null) {
                          return 'Please enter a valid number of years';
                        }
                        if (experienceYears > 20) {
                          return 'Experience cannot exceed 20 years';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildFormFieldLabel('Hourly Rate', textColor),
                    TextFormField(
                      controller: _hourlyRateController,
                      style: TextStyle(color: textColor),
                      decoration: _buildInputDecoration(
                        context: context,
                        hintText: 'Enter Rate per Hour',
                        icon: Ionicons.cash_outline,
                      ),
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter hourly rate';
                        }
                        if (double.tryParse(value.trim()) == null) {
                          return 'Please enter a valid number';
                        }
                        if (double.parse(value.trim()) <= 0) {
                          return 'Rate must be positive';
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
                        if (value?.isEmpty ?? true) {
                          return 'Please enter a password';
                        }
                        if (value!.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
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
                        if (value?.isEmpty ?? true) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signupWorker,
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
                                'Register as Worker',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Align(
                      alignment: Alignment.center,
                      child: OutlinedButton(
                        onPressed: () {
                          if (Navigator.canPop(context)) Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryColor,
                          side: BorderSide(
                            color: primaryColor.withOpacity(0.5),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 25,
                            vertical: 12,
                          ),
                        ),
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.inter(fontSize: 13),
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
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
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
    final Color borderColor = isDark
        ? Colors.grey.shade600
        : Colors.grey.shade300;
    final Color fillColor = isDark
        ? theme.inputDecorationTheme.fillColor ?? Colors.grey.shade800
        : Colors.white;

    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.inter(color: theme.hintColor, fontSize: 14),
      prefixIcon: icon != null
          ? Padding(
              padding: const EdgeInsets.only(left: 15.0, right: 10.0),
              child: Icon(icon, color: primaryColor, size: 20),
            )
          : null,
      prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: theme.colorScheme.error, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: theme.colorScheme.error, width: 1.5),
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _adhaarController.dispose();
    _addressController.dispose();
    _skillController.dispose();
    _experienceController.dispose();
    _hourlyRateController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
