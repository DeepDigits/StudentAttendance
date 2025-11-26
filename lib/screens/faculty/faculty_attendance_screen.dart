// Faculty Attendance Screen - View attendance records of students in their department
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ionicons/ionicons.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:attendance_tracking/providers/settings_provider.dart';
import 'package:attendance_tracking/config/api_config.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';

class FacultyAttendanceScreen extends StatefulWidget {
  final String? department;
  final String? profileId;

  const FacultyAttendanceScreen({super.key, this.department, this.profileId});

  @override
  State<FacultyAttendanceScreen> createState() =>
      _FacultyAttendanceScreenState();
}

class _FacultyAttendanceScreenState extends State<FacultyAttendanceScreen> {
  List<Map<String, dynamic>> _attendanceRecords = [];
  List<Map<String, dynamic>> _filteredRecords = [];
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String? _selectedStudent;
  String _filterType = 'all'; // 'all', 'present', 'absent', 'late'

  @override
  void initState() {
    super.initState();
    _loadAttendanceData();
    _loadStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    try {
      final url = widget.profileId != null
          ? '${ApiConfig.baseUrl}/api/faculty/${widget.profileId}/students/'
          : '${ApiConfig.baseUrl}/api/faculty/department-students/?department=${widget.department ?? ''}';

      final response = await http
          .get(Uri.parse(url), headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _students = data.map((e) => e as Map<String, dynamic>).toList();
        });
      }
    } catch (e) {
      print('Error loading students: $e');
    }
  }

  Future<void> _loadAttendanceData() async {
    setState(() => _isLoading = true);

    try {
      String url =
          '${ApiConfig.baseUrl}/api/faculty/department-attendance/?department=${widget.department ?? ''}';

      // Add date filter
      url += '&date=${DateFormat('yyyy-MM-dd').format(_selectedDate)}';

      // Add student filter if selected
      if (_selectedStudent != null) {
        url += '&student_id=$_selectedStudent';
      }

      print('Loading attendance from: $url'); // Debug log

      final response = await http
          .get(Uri.parse(url), headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));

      print('Response status: ${response.statusCode}'); // Debug log
      print('Response body: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _attendanceRecords = data
              .map((e) => e as Map<String, dynamic>)
              .toList();
          _applyFilters();
          _isLoading = false;
        });
      } else {
        print('Error response: ${response.body}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading attendance: $e');
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_attendanceRecords);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((record) {
        final name = '${record['student_name'] ?? ''}'.toLowerCase();
        final rollNo = '${record['roll_number'] ?? ''}'.toLowerCase();
        return name.contains(_searchQuery) || rollNo.contains(_searchQuery);
      }).toList();
    }

    // Apply status filter
    if (_filterType != 'all') {
      filtered = filtered.where((record) {
        final status = '${record['status'] ?? ''}'.toLowerCase();
        return status == _filterType;
      }).toList();
    }

    setState(() {
      _filteredRecords = filtered;
    });
  }

  void _filterBySearch(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.purple,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      // Always reload data when a date is picked
      setState(() {
        _selectedDate = picked;
      });
      await _loadAttendanceData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Use purple theme for faculty
    const MaterialColor primaryColor = Colors.purple;
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Filters Section
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          color: Colors.transparent,
          child: Column(
            children: [
              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900] : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterBySearch,
                  decoration: InputDecoration(
                    hintText: 'Search by name or roll number...',
                    hintStyle: GoogleFonts.inter(
                      color: isDark ? Colors.grey[500] : Colors.grey[400],
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Ionicons.search_outline,
                      color: isDark ? Colors.grey[500] : Colors.grey[400],
                      size: 20,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Ionicons.close_circle,
                              color: Colors.grey,
                              size: 20,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _filterBySearch('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  style: GoogleFonts.inter(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Date and Filter Row
              Row(
                children: [
                  // Date Picker
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[900] : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('MMM dd, yyyy').format(_selectedDate),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            Icon(
                              Ionicons.calendar_outline,
                              color: primaryColor,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Status Filter Dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[900] : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _filterType,
                        dropdownColor: isDark ? Colors.grey[900] : Colors.white,
                        icon: Icon(
                          Ionicons.chevron_down_outline,
                          size: 16,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All')),
                          DropdownMenuItem(
                            value: 'present',
                            child: Text('Present'),
                          ),
                          DropdownMenuItem(
                            value: 'absent',
                            child: Text('Absent'),
                          ),
                          DropdownMenuItem(value: 'late', child: Text('Late')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _filterType = value!;
                          });
                          _applyFilters();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Statistics Cards
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              _buildStatCard(
                'Total',
                _attendanceRecords.length.toString(),
                Ionicons.people_outline,
                primaryColor,
                isDark,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                'Present',
                _attendanceRecords
                    .where((r) => r['status']?.toLowerCase() == 'present')
                    .length
                    .toString(),
                Ionicons.checkmark_circle_outline,
                Colors.green,
                isDark,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                'Absent',
                _attendanceRecords
                    .where((r) => r['status']?.toLowerCase() == 'absent')
                    .length
                    .toString(),
                Ionicons.close_circle_outline,
                Colors.red,
                isDark,
              ),
            ],
          ),
        ),

        // Attendance Records List
        Expanded(
          child: _isLoading
              ? Center(
                  child: SpinKitFadingCircle(color: primaryColor, size: 50.0),
                )
              : _filteredRecords.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Ionicons.calendar_outline,
                        size: 64,
                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No attendance records found',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try selecting a different date',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: isDark ? Colors.grey[600] : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAttendanceData,
                  color: primaryColor,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _filteredRecords.length,
                    itemBuilder: (context, index) {
                      final record = _filteredRecords[index];
                      return _buildAttendanceCard(record, primaryColor, isDark);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceCard(
    Map<String, dynamic> record,
    Color primaryColor,
    bool isDark,
  ) {
    final status = record['status']?.toString().toLowerCase() ?? 'unknown';
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case 'present':
        statusColor = const Color(0xFF4CAF50); // Material Green
        statusIcon = Ionicons.checkmark_circle;
        statusText = 'Present';
        break;
      case 'absent':
        statusColor = const Color(0xFFE53935); // Material Red
        statusIcon = Ionicons.close_circle;
        statusText = 'Absent';
        break;
      case 'late':
        statusColor = Colors.orange;
        statusIcon = Ionicons.time;
        statusText = 'Late';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Ionicons.help_circle;
        statusText = 'Unknown';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showAttendanceDetails(record, isDark, primaryColor),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        primaryColor.withOpacity(0.5),
                        primaryColor.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: isDark ? Colors.grey[800] : Colors.white,
                    backgroundImage:
                        record['profile_pic'] != null &&
                            record['profile_pic'].toString().isNotEmpty
                        ? NetworkImage(record['profile_pic'])
                        : null,
                    child:
                        record['profile_pic'] == null ||
                            record['profile_pic'].toString().isEmpty
                        ? Icon(
                            Ionicons.person,
                            color: isDark ? Colors.grey[500] : Colors.grey[400],
                            size: 24,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record['student_name'] ?? 'Unknown Student',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Roll No: ${record['roll_number'] ?? 'N/A'}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                        ),
                      ),
                      if (record['check_in_time'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Check-in: ${record['check_in_time']}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isDark ? Colors.grey[600] : Colors.grey[500],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        statusText,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
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
    );
  }

  void _showAttendanceDetails(
    Map<String, dynamic> record,
    bool isDark,
    Color primaryColor,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Student Avatar
            CircleAvatar(
              radius: 40,
              backgroundColor: primaryColor.withOpacity(0.1),
              backgroundImage:
                  record['profile_pic'] != null &&
                      record['profile_pic'].toString().isNotEmpty
                  ? NetworkImage(record['profile_pic'])
                  : null,
              child:
                  record['profile_pic'] == null ||
                      record['profile_pic'].toString().isEmpty
                  ? Icon(Ionicons.person, size: 40, color: primaryColor)
                  : null,
            ),
            const SizedBox(height: 16),

            // Student Name
            Text(
              record['student_name'] ?? 'Unknown Student',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              record['roll_number'] ?? '',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),

            // Details
            _buildDetailRow(
              'Date',
              DateFormat('MMM dd, yyyy').format(_selectedDate),
              isDark,
            ),
            _buildDetailRow('Status', record['status'] ?? 'N/A', isDark),
            _buildDetailRow(
              'Check-in Time',
              record['check_in_time'] ?? 'N/A',
              isDark,
            ),
            if (record['check_out_time'] != null)
              _buildDetailRow(
                'Check-out Time',
                record['check_out_time'],
                isDark,
              ),
            if (record['location'] != null)
              _buildDetailRow('Location', record['location'], isDark),

            const SizedBox(height: 24),

            // Close Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Close',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? Colors.grey[500] : Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
}
