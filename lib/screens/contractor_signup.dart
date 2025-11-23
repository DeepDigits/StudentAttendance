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

class ContractorSignupPage extends StatefulWidget {
  const ContractorSignupPage({super.key});

  @override
  State<ContractorSignupPage> createState() => _ContractorSignupPageState();
}

class _ContractorSignupPageState extends State<ContractorSignupPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _licenseController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  File? _selectedProfilePic;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;

  String? _selectedDistrict;
  String? _selectedDivision;

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

  final List<String> _divisions = [
    'Division A',
    'Division B',
    'Division C',
    'Division D',
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

  Future<void> _signupContractor() async {
    final bool isValid = _formKey.currentState!.validate();

    setState(() {});

    if (!isValid || _selectedDistrict == null || _selectedDivision == null) {
      if (_selectedDistrict == null)
        ToastUtils.showErrorToast('Please select a district.');
      if (_selectedDivision == null)
        ToastUtils.showErrorToast('Please select a division.');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      ToastUtils.showErrorToast('Passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final Uri url = Uri.parse('${ApiConfig.baseUrl}/api/register/contractor/');

    var request = http.MultipartRequest('POST', url);

    request.fields['name'] = _nameController.text.trim();
    request.fields['email'] = _emailController.text.trim();
    request.fields['password'] = _passwordController.text;
    request.fields['address'] = _addressController.text.trim();
    request.fields['district'] = _selectedDistrict!;
    request.fields['city'] = _cityController.text.trim();
    request.fields['division'] = _selectedDivision!;
    request.fields['pincode'] = _pincodeController.text.trim();
    request.fields['phone'] = _phoneController.text.trim();
    request.fields['license_no'] = _licenseController.text.trim();

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
          data['message'] ??
              'Contractor registered successfully! Please log in.',
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
    final Color cardColor = theme.cardColor;
    final Color borderColor = isDark
        ? Colors.grey.shade700
        : Colors.grey.shade300;

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
                'https://imgs.search.brave.com/oKVArs5-ppima_8yYLv77cUDaBKAbBABy8IkLAQ6osA/rs:fit:860:0:0:0/g:ce/aHR0cHM6Ly9kMW5o/aW8wb3g3cGdiLmNs/b3VkZnJvbnQubmV0/L19pbWcvb19jb2xs/ZWN0aW9uX3BuZy9n/cmVlbl9kYXJrX2dy/ZXkvNTEyeDUxMi9w/bGFpbi93b3JrZXIu/cG5n',
                height: 50,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Ionicons.business_outline,
                    size: 50,
                    color: primaryColor,
                  );
                },
              ),
              const SizedBox(height: 15),
              Text(
                'Contractor Registration',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create your contractor profile',
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
                                ? "Add Profile Picture (Optional)"
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
                    _buildFormFieldLabel('Name', textColor),
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
                        color: subtleTextColor,
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    const SizedBox(height: 12),
                    _buildFormFieldLabel('City', textColor),
                    TextFormField(
                      controller: _cityController,
                      style: TextStyle(color: textColor),
                      decoration: _buildInputDecoration(
                        context: context,
                        hintText: 'Enter City',
                        icon: Ionicons.map_outline,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter city';
                        }
                        if (RegExp(r'[0-9]').hasMatch(value)) {
                          return 'City name cannot contain numbers';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildFormFieldLabel('Division', textColor),
                    DropdownButtonFormField<String>(
                      value: _selectedDivision,
                      style: TextStyle(color: textColor),
                      dropdownColor: isDark
                          ? Colors.grey.shade800
                          : Colors.white,
                      items: _divisions.map((String division) {
                        return DropdownMenuItem<String>(
                          value: division,
                          child: Text(
                            division,
                            style: GoogleFonts.inter(fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedDivision = newValue;
                        });
                      },
                      decoration:
                          _buildInputDecoration(
                            context: context,
                            hintText: 'Select Division',
                            icon: Ionicons.grid_outline,
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
                                Ionicons.grid_outline,
                                color: primaryColor,
                                size: 20,
                              ),
                            ),
                          ),
                      validator: (value) =>
                          value == null ? 'Please select a division' : null,
                      isExpanded: true,
                      icon: Icon(
                        Ionicons.chevron_down_outline,
                        color: subtleTextColor,
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    const SizedBox(height: 12),
                    _buildFormFieldLabel('Pincode', textColor),
                    TextFormField(
                      controller: _pincodeController,
                      style: TextStyle(color: textColor),
                      decoration: _buildInputDecoration(
                        context: context,
                        hintText: 'Enter Pincode',
                        icon: Ionicons.pin_outline,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter pincode';
                        }
                        if (value.trim().length != 6) {
                          return 'Pincode must be 6 digits';
                        }
                        return null;
                      },
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
                    _buildFormFieldLabel('License Number', textColor),
                    TextFormField(
                      controller: _licenseController,
                      style: TextStyle(color: textColor),
                      decoration: _buildInputDecoration(
                        context: context,
                        hintText: 'Enter License Number',
                        icon: Ionicons.id_card_outline,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter license number';
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
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signupContractor,
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
                                'Register as Contractor',
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
    _nameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _phoneController.dispose();
    _licenseController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
