import 'package:flutter/material.dart';
import 'package:attendance_tracking/config/api_config.dart';
import 'package:attendance_tracking/utils/snackbar_utils.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ionicons/ionicons.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:attendance_tracking/providers/settings_provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class PostJobView extends StatefulWidget {
  final String userId;

  const PostJobView({super.key, required this.userId});

  @override
  State<PostJobView> createState() => _PostJobViewState();
}

class _PostJobViewState extends State<PostJobView> {
  // Form key and controllers
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();

  // Dropdown values
  String? _selectedJobType;
  String? _selectedWorkEnvironment;
  String? _selectedContractorId;
  // Loading states
  bool _isLoading = false;
  bool _isLoadingContractors = true;

  // Contractors list
  List<Map<String, dynamic>> _contractors = [];

  // Job type and work environment options
  final List<String> _jobTypes = ['Full Time', 'Part Time', 'Seasonal'];
  final List<String> _workEnvironments = ['Indoor', 'Outdoor', 'Factory'];
  @override
  void initState() {
    super.initState();
    _fetchContractors();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // Fetch contractors for the dropdown
  Future<void> _fetchContractors() async {
    setState(() {
      _isLoadingContractors = true;
    });

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/contractors/list/'),
        headers: {'Accept': 'application/json'},
      );

      if (mounted) {
        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          setState(() {
            _contractors = data
                .map((item) => Map<String, dynamic>.from(item))
                .toList();
            _isLoadingContractors = false;
          });
        } else {
          setState(() {
            _isLoadingContractors = false;
          });
          ToastUtils.showErrorToast('Failed to load contractors');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingContractors = false;
        });
        ToastUtils.showErrorToast('Error: $e');
      }
    }
  }

  // Submit the job posting
  Future<void> _submitJobPosting() async {
    if (_formKey.currentState!.validate()) {
      // Validate contractor selection
      if (_selectedContractorId == null) {
        ToastUtils.showErrorToast('Please select a contractor');
        return;
      }

      setState(() {
        _isLoading = true;
      });
      try {
        final response = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/api/jobs/create/'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: json.encode({
            'title': _titleController.text.trim(),
            'description': _descriptionController.text.trim(),
            'address': _addressController.text.trim(),
            'job_type': _selectedJobType,
            'work_environment': _selectedWorkEnvironment,
            'contractor_id': _selectedContractorId,
            'user_id': widget.userId,
          }),
        );

        if (!mounted) return;

        if (response.statusCode == 201) {
          // Clear form after successful submission
          _formKey.currentState!.reset();
          _titleController.clear();
          _descriptionController.clear();
          _addressController.clear();
          setState(() {
            _selectedJobType = null;
            _selectedWorkEnvironment = null;
            _selectedContractorId = null;
          });

          ToastUtils.showSuccessToast('Job posted successfully!');
        } else {
          final data = json.decode(response.body);
          ToastUtils.showErrorToast(data['error'] ?? 'Failed to post job');
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
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final Color primaryColor = settingsProvider.primaryColor;

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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page Title
                Text(
                  'Post a New Job',
                  style: GoogleFonts.outfit(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Fill out the form below to create a new job posting',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    color: subtleTextColor,
                  ),
                ),
                const SizedBox(height: 30),

                // Form Card
                Card(
                  color: cardColor,
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: borderColor, width: 0.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Job Title
                          TextFormField(
                            controller: _titleController,
                            decoration: InputDecoration(
                              labelText: 'Job Title',
                              hintText: 'Enter the job title',
                              prefixIcon: Icon(
                                Ionicons.briefcase_outline,
                                color: primaryColor,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 16,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a job title';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Description
                          TextFormField(
                            controller: _descriptionController,
                            decoration: InputDecoration(
                              labelText: 'Description',
                              hintText: 'Enter the job description',
                              prefixIcon: Icon(
                                Ionicons.document_text_outline,
                                color: primaryColor,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 16,
                              ),
                            ),
                            maxLines: 5,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a job description';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Address
                          TextFormField(
                            controller: _addressController,
                            decoration: InputDecoration(
                              labelText: 'Address',
                              hintText: 'Enter the job location',
                              prefixIcon: Icon(
                                Ionicons.location_outline,
                                color: primaryColor,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 16,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a job location';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Job Type Dropdown
                          DropdownButtonFormField<String>(
                            value: _selectedJobType,
                            decoration: InputDecoration(
                              labelText: 'Job Type',
                              prefixIcon: Icon(
                                Ionicons.time_outline,
                                color: primaryColor,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 16,
                              ),
                            ),
                            items: _jobTypes.map((String type) {
                              return DropdownMenuItem<String>(
                                value: type,
                                child: Text(type),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedJobType = newValue;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Please select a job type';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Work Environment Dropdown
                          DropdownButtonFormField<String>(
                            value: _selectedWorkEnvironment,
                            decoration: InputDecoration(
                              labelText: 'Work Environment',
                              prefixIcon: Icon(
                                Ionicons.business_outline,
                                color: primaryColor,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 16,
                              ),
                            ),
                            items: _workEnvironments.map((String env) {
                              return DropdownMenuItem<String>(
                                value: env,
                                child: Text(env),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedWorkEnvironment = newValue;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Please select a work environment';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Contractor Dropdown
                          _isLoadingContractors
                              ? Center(
                                  child: SpinKitFadingCircle(
                                    color: primaryColor,
                                    size: 30.0,
                                  ),
                                )
                              : DropdownButtonFormField<String>(
                                  value: _selectedContractorId,
                                  decoration: InputDecoration(
                                    labelText: 'Contractor',
                                    prefixIcon: Icon(
                                      Ionicons.person_outline,
                                      color: primaryColor,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                      horizontal: 16,
                                    ),
                                  ),
                                  items: _contractors.isEmpty
                                      ? [
                                          const DropdownMenuItem<String>(
                                            value: null,
                                            child: Text(
                                              'No contractors available',
                                            ),
                                          ),
                                        ]
                                      : _contractors.map((contractor) {
                                          return DropdownMenuItem<String>(
                                            value: contractor['id'].toString(),
                                            child: Text(
                                              '${contractor['name']} - ${contractor['city']}',
                                            ),
                                          );
                                        }).toList(),
                                  onChanged: _contractors.isEmpty
                                      ? null
                                      : (String? newValue) {
                                          setState(() {
                                            _selectedContractorId = newValue;
                                          });
                                        },
                                  validator: (value) {
                                    if (value == null) {
                                      return 'Please select a contractor';
                                    }
                                    return null;
                                  },
                                ),
                          const SizedBox(height: 30),

                          // Submit Button
                          ElevatedButton(
                            onPressed: _isLoading ? null : _submitJobPosting,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              disabledBackgroundColor: primaryColor.withOpacity(
                                0.5,
                              ),
                            ),
                            child: _isLoading
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Posting Job...',
                                        style: GoogleFonts.outfit(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Ionicons.add_circle_outline),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Post Job',
                                        style: GoogleFonts.outfit(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
