import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ionicons/ionicons.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:attendance_tracking/config/api_config.dart';

// Student model for attendance tracking system
class Student {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? rollNumber;
  final String? department;
  final String? yearOfStudy;
  final String? section;
  final String? profilePicUrl;
  final String? approvalStatus; // pending, approved, rejected
  final DateTime? createdAt;

  Student({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.rollNumber,
    this.department,
    this.yearOfStudy,
    this.section,
    this.profilePicUrl,
    this.approvalStatus,
    this.createdAt,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] ?? 0,
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      rollNumber: json['roll_number'],
      department: json['department'],
      yearOfStudy: json['year_of_study'],
      section: json['section'],
      profilePicUrl: json['profile_pic_url'],
      approvalStatus: json['approval_status'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  String get fullName => '$firstName $lastName';
}

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  late Future<List<Student>> _studentRequestsFuture;
  Future<List<Student>> _approvedStudentsFuture = Future.value([]);

  @override
  void initState() {
    super.initState();
    _studentRequestsFuture = _fetchStudentRequests();
    _approvedStudentsFuture = _fetchApprovedStudents();
  }

  // Fetch pending student registration requests
  Future<List<Student>> _fetchStudentRequests() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/students/pending/'),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Student.fromJson(json)).toList();
      } else {
        throw Exception(
          'Failed to load student requests: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching student requests: $e');
      throw Exception('Failed to load student requests');
    }
  }

  // Fetch approved students
  Future<List<Student>> _fetchApprovedStudents() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/students/approved/'),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Student.fromJson(json)).toList();
      } else {
        throw Exception(
          'Failed to load approved students: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching approved students: $e');
      throw Exception('Failed to load approved students');
    }
  }

  Future<void> _refreshStudentRequests() async {
    if (mounted) {
      setState(() {
        _studentRequestsFuture = _fetchStudentRequests();
      });
    }
  }

  Future<void> _refreshApprovedStudents() async {
    if (mounted) {
      setState(() {
        _approvedStudentsFuture = _fetchApprovedStudents();
      });
    }
  }

  // Approve student request
  Future<void> _approveStudentRequest(int studentId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/students/approve/$studentId/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        Fluttertoast.showToast(
          msg: "Student approved successfully",
          toastLength: Toast.LENGTH_SHORT,
          backgroundColor: Colors.green,
        );
        _refreshStudentRequests();
        _refreshApprovedStudents();
      } else {
        throw Exception('Failed to approve student');
      }
    } catch (e) {
      print('Error approving student: $e');
      Fluttertoast.showToast(
        msg: "Error approving student",
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: Colors.red,
      );
    }
  }

  // Reject student request
  Future<void> _rejectStudentRequest(int studentId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/students/reject/$studentId/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        Fluttertoast.showToast(
          msg: "Student rejected",
          toastLength: Toast.LENGTH_SHORT,
          backgroundColor: Colors.orange,
        );
        _refreshStudentRequests();
      } else {
        throw Exception('Failed to reject student');
      }
    } catch (e) {
      print('Error rejecting student: $e');
      Fluttertoast.showToast(
        msg: "Error rejecting student",
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
              Tab(text: 'Enrolled Students'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildStudentRequestsTab(isDark),
            _buildApprovedStudentsTab(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentRequestsTab(bool isDark) {
    return RefreshIndicator(
      onRefresh: _refreshStudentRequests,
      child: FutureBuilder<List<Student>>(
        future: _studentRequestsFuture,
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
              'No student registration requests at the moment',
              Ionicons.school_outline,
            );
          }

          final students = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: students.length,
            itemBuilder: (context, index) {
              return _buildStudentRequestCard(students[index], isDark);
            },
          );
        },
      ),
    );
  }

  Widget _buildApprovedStudentsTab(bool isDark) {
    return RefreshIndicator(
      onRefresh: _refreshApprovedStudents,
      child: FutureBuilder<List<Student>>(
        future: _approvedStudentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: SpinKitFadingCircle(color: Colors.blue, size: 50.0),
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState(
              'No Enrolled Students',
              'Enrolled students will appear here',
              Ionicons.people_outline,
            );
          }

          final students = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: students.length,
            itemBuilder: (context, index) {
              return _buildStudentCard(students[index], isDark);
            },
          );
        },
      ),
    );
  }

  Widget _buildStudentRequestCard(Student student, bool isDark) {
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
                  backgroundImage: student.profilePicUrl != null
                      ? NetworkImage(student.profilePicUrl!)
                      : null,
                  child: student.profilePicUrl == null
                      ? Text(
                          student.firstName[0].toUpperCase(),
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
                        student.fullName,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        student.email,
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
            if (student.rollNumber != null)
              _buildInfoRow(
                Ionicons.id_card_outline,
                'Roll Number',
                student.rollNumber!,
              ),
            if (student.department != null)
              _buildInfoRow(
                Ionicons.business_outline,
                'Department',
                student.department!,
              ),
            if (student.yearOfStudy != null)
              _buildInfoRow(
                Ionicons.calendar_outline,
                'Year',
                student.yearOfStudy!,
              ),
            if (student.section != null)
              _buildInfoRow(Ionicons.grid_outline, 'Section', student.section!),
            if (student.phone != null)
              _buildInfoRow(Ionicons.call_outline, 'Phone', student.phone!),
            if (student.createdAt != null)
              _buildInfoRow(
                Ionicons.time_outline,
                'Requested on',
                DateFormat('MMM d, yyyy').format(student.createdAt!),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approveStudentRequest(student.id),
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
                    onPressed: () => _rejectStudentRequest(student.id),
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

  Widget _buildStudentCard(Student student, bool isDark) {
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
                  backgroundImage: student.profilePicUrl != null
                      ? NetworkImage(student.profilePicUrl!)
                      : null,
                  child: student.profilePicUrl == null
                      ? Text(
                          student.firstName[0].toUpperCase(),
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
                        student.fullName,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        student.email,
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
                    'Enrolled',
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
            if (student.rollNumber != null)
              _buildInfoRow(
                Ionicons.id_card_outline,
                'Roll Number',
                student.rollNumber!,
              ),
            if (student.department != null)
              _buildInfoRow(
                Ionicons.business_outline,
                'Department',
                student.department!,
              ),
            if (student.yearOfStudy != null)
              _buildInfoRow(
                Ionicons.calendar_outline,
                'Year',
                student.yearOfStudy!,
              ),
            if (student.section != null)
              _buildInfoRow(Ionicons.grid_outline, 'Section', student.section!),
            if (student.phone != null)
              _buildInfoRow(Ionicons.call_outline, 'Phone', student.phone!),
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
