import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ionicons/ionicons.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:attendance_tracking/config/api_config.dart';

// Faculty model for attendance tracking system
class Faculty {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? employeeId;
  final String? department;
  final String? qualifications;
  final String? profilePicUrl;
  final String? approvalStatus; // pending, approved, rejected
  final DateTime? createdAt;

  Faculty({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.employeeId,
    this.department,
    this.qualifications,
    this.profilePicUrl,
    this.approvalStatus,
    this.createdAt,
  });

  factory Faculty.fromJson(Map<String, dynamic> json) {
    return Faculty(
      id: json['id'] ?? 0,
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      employeeId: json['employee_id'],
      department: json['department'],
      qualifications: json['qualifications'],
      profilePicUrl: json['profile_pic_url'],
      approvalStatus: json['approval_status'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  String get fullName => '$firstName $lastName';
}

class FacultyScreen extends StatefulWidget {
  const FacultyScreen({super.key});

  @override
  State<FacultyScreen> createState() => _FacultyScreenState();
}

class _FacultyScreenState extends State<FacultyScreen> {
  late Future<List<Faculty>> _facultyRequestsFuture;
  Future<List<Faculty>> _approvedFacultyFuture = Future.value([]);

  @override
  void initState() {
    super.initState();
    _facultyRequestsFuture = _fetchFacultyRequests();
    _approvedFacultyFuture = _fetchApprovedFaculty();
  }

  // Fetch pending faculty registration requests
  Future<List<Faculty>> _fetchFacultyRequests() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/faculty/pending/'),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Faculty.fromJson(json)).toList();
      } else {
        throw Exception(
          'Failed to load faculty requests: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching faculty requests: $e');
      throw Exception('Failed to load faculty requests');
    }
  }

  // Fetch approved faculty members
  Future<List<Faculty>> _fetchApprovedFaculty() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/faculty/approved/'),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Faculty.fromJson(json)).toList();
      } else {
        throw Exception(
          'Failed to load approved faculty: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching approved faculty: $e');
      throw Exception('Failed to load approved faculty');
    }
  }

  Future<void> _refreshFacultyRequests() async {
    if (mounted) {
      setState(() {
        _facultyRequestsFuture = _fetchFacultyRequests();
      });
    }
  }

  Future<void> _refreshApprovedFaculty() async {
    if (mounted) {
      setState(() {
        _approvedFacultyFuture = _fetchApprovedFaculty();
      });
    }
  }

  // Approve faculty request
  Future<void> _approveFacultyRequest(int facultyId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/faculty/approve/$facultyId/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        Fluttertoast.showToast(
          msg: "Faculty approved successfully",
          toastLength: Toast.LENGTH_SHORT,
          backgroundColor: Colors.green,
        );
        _refreshFacultyRequests();
        _refreshApprovedFaculty();
      } else {
        throw Exception('Failed to approve faculty');
      }
    } catch (e) {
      print('Error approving faculty: $e');
      Fluttertoast.showToast(
        msg: "Error approving faculty",
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: Colors.red,
      );
    }
  }

  // Reject faculty request
  Future<void> _rejectFacultyRequest(int facultyId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/faculty/reject/$facultyId/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        Fluttertoast.showToast(
          msg: "Faculty rejected",
          toastLength: Toast.LENGTH_SHORT,
          backgroundColor: Colors.orange,
        );
        _refreshFacultyRequests();
      } else {
        throw Exception('Failed to reject faculty');
      }
    } catch (e) {
      print('Error rejecting faculty: $e');
      Fluttertoast.showToast(
        msg: "Error rejecting faculty",
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: isDark ? Color(0xFF131313) : Colors.white,
          elevation: 0,
          toolbarHeight: 0,
          bottom: TabBar(
            indicatorColor: theme.colorScheme.primary,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: isDark
                ? Colors.grey.shade400
                : Colors.grey.shade600,
            labelStyle: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            tabs: const [
              Tab(text: 'Pending Requests'),
              Tab(text: 'Approved Faculty'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildFacultyRequestsTab(isDark),
            _buildApprovedFacultyTab(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildFacultyRequestsTab(bool isDark) {
    return RefreshIndicator(
      onRefresh: _refreshFacultyRequests,
      child: FutureBuilder<List<Faculty>>(
        future: _facultyRequestsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: SpinKitFadingCircle(color: Colors.blue, size: 50.0),
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState(
              'No Pending Requests',
              'No faculty registration requests at the moment',
              Ionicons.people_outline,
            );
          }

          final faculties = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: faculties.length,
            itemBuilder: (context, index) {
              return _buildFacultyRequestCard(faculties[index], isDark);
            },
          );
        },
      ),
    );
  }

  Widget _buildApprovedFacultyTab(bool isDark) {
    return RefreshIndicator(
      onRefresh: _refreshApprovedFaculty,
      child: FutureBuilder<List<Faculty>>(
        future: _approvedFacultyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: SpinKitFadingCircle(color: Colors.blue, size: 50.0),
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState(
              'No Approved Faculty',
              'Approved faculty members will appear here',
              Ionicons.checkmark_circle_outline,
            );
          }

          final faculties = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: faculties.length,
            itemBuilder: (context, index) {
              return _buildFacultyCard(faculties[index], isDark);
            },
          );
        },
      ),
    );
  }

  Widget _buildFacultyRequestCard(Faculty faculty, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isDark ? 2 : 1,
      color: isDark ? Color(0xFF131313) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Color(0xFF2A2A2A) : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: faculty.profilePicUrl != null
                      ? NetworkImage(faculty.profilePicUrl!)
                      : null,
                  child: faculty.profilePicUrl == null
                      ? Text(
                          faculty.firstName[0].toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        faculty.fullName,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        faculty.email,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (faculty.employeeId != null)
              _buildInfoRow(
                Ionicons.id_card_outline,
                'Employee ID',
                faculty.employeeId!,
              ),
            if (faculty.department != null)
              _buildInfoRow(
                Ionicons.business_outline,
                'Department',
                faculty.department!,
              ),
            if (faculty.qualifications != null)
              _buildInfoRow(
                Ionicons.school_outline,
                'Qualifications',
                faculty.qualifications!,
              ),
            if (faculty.phone != null)
              _buildInfoRow(Ionicons.call_outline, 'Phone', faculty.phone!),
            if (faculty.createdAt != null)
              _buildInfoRow(
                Ionicons.calendar_outline,
                'Requested on',
                DateFormat('MMM d, yyyy').format(faculty.createdAt!),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approveFacultyRequest(faculty.id),
                    icon: const Icon(Ionicons.checkmark_circle_outline),
                    label: Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectFacultyRequest(faculty.id),
                    icon: const Icon(Ionicons.close_circle_outline),
                    label: Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFacultyCard(Faculty faculty, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isDark ? 2 : 1,
      color: isDark ? Color(0xFF131313) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Color(0xFF2A2A2A) : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: faculty.profilePicUrl != null
                      ? NetworkImage(faculty.profilePicUrl!)
                      : null,
                  child: faculty.profilePicUrl == null
                      ? Text(
                          faculty.firstName[0].toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        faculty.fullName,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        faculty.email,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Approved',
                    style: GoogleFonts.outfit(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (faculty.employeeId != null)
              _buildInfoRow(
                Ionicons.id_card_outline,
                'Employee ID',
                faculty.employeeId!,
              ),
            if (faculty.department != null)
              _buildInfoRow(
                Ionicons.business_outline,
                'Department',
                faculty.department!,
              ),
            if (faculty.qualifications != null)
              _buildInfoRow(
                Ionicons.school_outline,
                'Qualifications',
                faculty.qualifications!,
              ),
            if (faculty.phone != null)
              _buildInfoRow(Ionicons.call_outline, 'Phone', faculty.phone!),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          Expanded(child: Text(value, style: GoogleFonts.outfit(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
