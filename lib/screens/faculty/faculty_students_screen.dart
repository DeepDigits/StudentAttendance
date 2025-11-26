// Faculty Students Screen - View students in their department
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ionicons/ionicons.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:attendance_tracking/providers/settings_provider.dart';
import 'package:attendance_tracking/config/api_config.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class FacultyStudentsScreen extends StatefulWidget {
  final String? department;
  final String? profileId;

  const FacultyStudentsScreen({super.key, this.department, this.profileId});

  @override
  State<FacultyStudentsScreen> createState() => _FacultyStudentsScreenState();
}

class _FacultyStudentsScreenState extends State<FacultyStudentsScreen> {
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _filteredStudents = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);

    try {
      final url = widget.profileId != null && widget.profileId!.isNotEmpty
          ? '${ApiConfig.baseUrl}/api/faculty/${widget.profileId}/students/'
          : '${ApiConfig.baseUrl}/api/faculty/department-students/?department=${Uri.encodeComponent(widget.department ?? '')}';

      print('Loading students from: $url'); // Debug log

      final response = await http
          .get(Uri.parse(url), headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));

      print('Response status: ${response.statusCode}'); // Debug log
      print('Response body: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        final List<dynamic> data = responseData is List ? responseData : [];
        setState(() {
          _students = data.map((e) => e as Map<String, dynamic>).toList();
          _filteredStudents = _students;
          _isLoading = false;
        });
      } else {
        print('Error response: ${response.body}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading students: $e');
      setState(() => _isLoading = false);
    }
  }

  void _filterStudents(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      if (_searchQuery.isEmpty) {
        _filteredStudents = _students;
      } else {
        _filteredStudents = _students.where((student) {
          final name = '${student['first_name']} ${student['last_name']}'
              .toLowerCase();
          final rollNo = (student['roll_number'] ?? '').toLowerCase();
          final email = (student['email'] ?? '').toLowerCase();
          return name.contains(_searchQuery) ||
              rollNo.contains(_searchQuery) ||
              email.contains(_searchQuery);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Use purple theme for faculty
    const MaterialColor primaryColor = Colors.purple;
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            onChanged: _filterStudents,
            decoration: InputDecoration(
              hintText: 'Search students...',
              hintStyle: GoogleFonts.inter(
                color: isDark ? Colors.grey[500] : Colors.grey[400],
              ),
              prefixIcon: Icon(
                Ionicons.search_outline,
                color: isDark ? Colors.grey[500] : Colors.grey[400],
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Ionicons.close_circle, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        _filterStudents('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: isDark ? Colors.grey[850] : Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            style: GoogleFonts.inter(
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),

        // Students Count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_filteredStudents.length} Students',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              IconButton(
                onPressed: _loadStudents,
                icon: Icon(Ionicons.refresh_outline, color: primaryColor),
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),

        // Students List
        Expanded(
          child: _isLoading
              ? Center(
                  child: SpinKitFadingCircle(color: primaryColor, size: 50.0),
                )
              : _filteredStudents.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Ionicons.people_outline,
                        size: 64,
                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'No students match your search'
                            : 'No students in your department',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadStudents,
                  color: primaryColor,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredStudents.length,
                    itemBuilder: (context, index) {
                      final student = _filteredStudents[index];
                      return _buildStudentCard(
                        context,
                        student,
                        primaryColor,
                        isDark,
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildStudentCard(
    BuildContext context,
    Map<String, dynamic> student,
    Color primaryColor,
    bool isDark,
  ) {
    final name = '${student['first_name'] ?? ''} ${student['last_name'] ?? ''}'
        .trim();
    final rollNumber = student['roll_number'] ?? 'N/A';
    final email = student['email'] ?? '';
    final year = student['year_of_study'] ?? '';
    final section = student['section'] ?? '';
    // Check both profile_pic and profile_pic_url for compatibility
    final profilePic = student['profile_pic'] ?? student['profile_pic_url'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () =>
              _showStudentDetails(context, student, primaryColor, isDark),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Profile Picture with gradient border
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade300, Colors.purple.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: isDark
                        ? Colors.grey[800]
                        : Colors.grey[100],
                    backgroundImage:
                        profilePic != null && profilePic.toString().isNotEmpty
                        ? NetworkImage(profilePic)
                        : null,
                    child: profilePic == null || profilePic.toString().isEmpty
                        ? Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'S',
                            style: GoogleFonts.outfit(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                // Student Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isNotEmpty ? name : 'Student',
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Ionicons.id_card_outline,
                                  size: 12,
                                  color: primaryColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  rollNumber,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (year != 'N/A' && year.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.grey[800]
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                year,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (section != 'N/A' && section.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            'Section $section',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.grey[500]
                                  : Colors.grey[500],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Arrow indicator
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Ionicons.chevron_forward,
                    color: primaryColor,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showStudentDetails(
    BuildContext context,
    Map<String, dynamic> student,
    Color primaryColor,
    bool isDark,
  ) {
    final name = '${student['first_name'] ?? ''} ${student['last_name'] ?? ''}'
        .trim();
    final profilePic = student['profile_pic'] ?? student['profile_pic_url'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Profile Picture with gradient border
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.purple.shade300,
                            Colors.purple.shade600,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 55,
                        backgroundColor: isDark
                            ? Colors.grey[800]
                            : Colors.grey[100],
                        backgroundImage:
                            profilePic != null &&
                                profilePic.toString().isNotEmpty
                            ? NetworkImage(profilePic)
                            : null,
                        child:
                            profilePic == null || profilePic.toString().isEmpty
                            ? Text(
                                name.isNotEmpty ? name[0].toUpperCase() : 'S',
                                style: GoogleFonts.outfit(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor,
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      name.isNotEmpty ? name : 'Student',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      student['email'] ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Details section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[850] : Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            Ionicons.id_card_outline,
                            'Roll Number',
                            student['roll_number'] ?? 'N/A',
                            primaryColor,
                            isDark,
                          ),
                          Divider(
                            height: 24,
                            color: isDark ? Colors.grey[800] : Colors.grey[200],
                          ),
                          _buildDetailRow(
                            Ionicons.school_outline,
                            'Year of Study',
                            student['year_of_study'] ?? 'N/A',
                            primaryColor,
                            isDark,
                          ),
                          Divider(
                            height: 24,
                            color: isDark ? Colors.grey[800] : Colors.grey[200],
                          ),
                          _buildDetailRow(
                            Ionicons.grid_outline,
                            'Section',
                            student['section'] ?? 'N/A',
                            primaryColor,
                            isDark,
                          ),
                          Divider(
                            height: 24,
                            color: isDark ? Colors.grey[800] : Colors.grey[200],
                          ),
                          _buildDetailRow(
                            Ionicons.call_outline,
                            'Phone',
                            student['phone'] ?? 'N/A',
                            primaryColor,
                            isDark,
                          ),
                          Divider(
                            height: 24,
                            color: isDark ? Colors.grey[800] : Colors.grey[200],
                          ),
                          _buildDetailRow(
                            Ionicons.business_outline,
                            'Department',
                            student['department'] ?? widget.department ?? 'N/A',
                            primaryColor,
                            isDark,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    Color primaryColor,
    bool isDark,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: primaryColor),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDark ? Colors.grey[500] : Colors.grey[500],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
