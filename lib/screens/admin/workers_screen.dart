import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ionicons/ionicons.dart';
import 'dart:ui'; // Import for ImageFilter if using blur
import 'package:fluttertoast/fluttertoast.dart'; // Import fluttertoast
import 'package:http/http.dart' as http; // Import http
import 'dart:convert'; // Import jsonDecode
import 'package:intl/intl.dart'; // For date formatting
import 'package:flutter_spinkit/flutter_spinkit.dart'; // Import SpinKit

// Updated Worker model to include fields relevant for requests
class Worker {
  final int id; // Changed id to int to match typical DB IDs
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? address;
  final String? adhaar;
  final String? profilePicUrl;
  final String? approvalStatus; // Added status
  final DateTime? createdAt; // Added creation time

  Worker({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.address,
    this.adhaar,
    this.profilePicUrl,
    this.approvalStatus,
    this.createdAt,
  });

  // Factory constructor to parse JSON from Django backend
  factory Worker.fromJson(Map<String, dynamic> json) {
    return Worker(
      id: json['id'] ?? 0, // Default to 0 if null
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      address: json['address'],
      adhaar: json['adhaar'],
      profilePicUrl: json['profile_pic_url'], // Assuming backend provides this
      approvalStatus: json['approval_status'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  String get fullName => '$firstName $lastName';
}

class WorkersScreen extends StatefulWidget {
  const WorkersScreen({super.key});

  @override
  State<WorkersScreen> createState() => _WorkersScreenState();
}

class _WorkersScreenState extends State<WorkersScreen> {
  // State variable for worker requests (pending)
  late Future<List<Worker>> _workerRequestsFuture;
  // State variable for approved workers - Initialize directly
  // REMOVE late keyword
  Future<List<Worker>> _approvedWorkersFuture =
      Future.value([]); // Initialize with an empty future first
  final String _baseApiUrl =
      'https://workersapp.pythonanywhere.com/api'; // Base URL

  @override
  void initState() {
    super.initState();
    // Initialize futures in initState
    _workerRequestsFuture = _fetchWorkerRequests();
    // Assign the actual fetch future here
    _approvedWorkersFuture = _fetchApprovedWorkers();
  }

  // Function to fetch PENDING worker requests from the backend
  Future<List<Worker>> _fetchWorkerRequests() async {
    try {
      final response =
          await http.get(Uri.parse('$_baseApiUrl/workerRequests/'));

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        // Use the Worker.fromJson factory
        return data.map((json) => Worker.fromJson(json)).toList();
      } else {
        throw Exception(
            'Failed to load worker requests: Status code ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching worker requests: $e');
      throw Exception(
          'Failed to load worker requests. Check connection or API endpoint.');
    }
  }

  // Function to fetch APPROVED workers from the backend
  Future<List<Worker>> _fetchApprovedWorkers() async {
    // This method now correctly uses the instance member _baseApiUrl
    try {
      // Use the new endpoint
      final response =
          await http.get(Uri.parse('$_baseApiUrl/workers/approved/'));

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Worker.fromJson(json)).toList();
      } else {
        throw Exception(
            'Failed to load approved workers: Status code ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching approved workers: $e');
      // Return an empty list or rethrow, depending on how you want to handle errors
      // Rethrowing allows FutureBuilder's error state to handle it.
      throw Exception(
          'Failed to load approved workers. Check connection or API endpoint.');
    }
  }

  // Function to refresh the PENDING worker requests list
  Future<void> _refreshWorkerRequests() async {
    if (mounted) {
      setState(() {
        // Re-assign the future when refreshing
        _workerRequestsFuture = _fetchWorkerRequests();
      });
    }
  }

  // Function to refresh the APPROVED workers list
  Future<void> _refreshApprovedWorkers() async {
    if (mounted) {
      setState(() {
        // Re-assign the future when refreshing
        _approvedWorkersFuture = _fetchApprovedWorkers();
      });
    }
  }

  // Function to accept a worker request via API
  Future<void> _acceptWorkerRequest(int workerId) async {
    final url = Uri.parse('$_baseApiUrl/workerRequests/$workerId/accept/');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        // No body needed for this specific POST request based on the backend view
      );

      if (response.statusCode == 200) {
        Fluttertoast.showToast(
          msg: "Worker approved successfully!",
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        // Refresh the list after successful acceptance
        _refreshWorkerRequests();
      } else {
        // Try to decode error message from backend
        String errorMessage = 'Failed to accept worker.';
        try {
          final responseBody = jsonDecode(response.body);
          if (responseBody['error'] != null) {
            errorMessage += ' Error: ${responseBody['error']}';
          } else if (responseBody['message'] != null) {
            // Handle cases where backend sends a message even on failure?
            errorMessage += ' Message: ${responseBody['message']}';
          }
        } catch (e) {
          // Ignore decoding error, use default message
        }
        Fluttertoast.showToast(
          msg: '$errorMessage (Status: ${response.statusCode})',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      print('Error accepting worker request: $e');
      Fluttertoast.showToast(
        msg: "An error occurred. Please check connection.",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  // Function to reject a worker request via API
  Future<void> _rejectWorkerRequest(int workerId, String reason) async {
    final url = Uri.parse('$_baseApiUrl/workerRequests/$workerId/reject/');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'reason': reason}), // Send reason in the body
      );

      if (response.statusCode == 200) {
        Fluttertoast.showToast(
          msg: "Worker rejected successfully!",
          backgroundColor: Colors.orange, // Use a different color for reject
          textColor: Colors.white,
        );
        // Refresh the list after successful rejection
        _refreshWorkerRequests();
      } else {
        // Try to decode error message from backend
        String errorMessage = 'Failed to reject worker.';
        try {
          final responseBody = jsonDecode(response.body);
          if (responseBody['error'] != null) {
            errorMessage += ' Error: ${responseBody['error']}';
          } else if (responseBody['message'] != null) {
            errorMessage += ' Message: ${responseBody['message']}';
          }
        } catch (e) {
          // Ignore decoding error
        }
        Fluttertoast.showToast(
          msg: '$errorMessage (Status: ${response.statusCode})',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      print('Error rejecting worker request: $e');
      Fluttertoast.showToast(
        msg: "An error occurred. Please check connection.",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  // Function to show the dialog for entering rejection reason
  Future<String?> _showRejectReasonDialog(
      BuildContext bottomSheetContext, Worker worker) async {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>(); // Key for the form

    // Use theme colors
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color headerColor =
        Colors.orange.shade700; // Keep specific color for reject
    final Color headerForegroundColor = Colors.white;
    final Color contentTextColor = theme.textTheme.bodyLarge?.color ??
        (isDark ? Colors.white70 : Colors.grey.shade800);
    final Color dialogBackgroundColor = theme.dialogBackgroundColor;
    final Color inputFillColor = theme.inputDecorationTheme.fillColor ??
        (isDark ? Colors.grey.shade800 : Colors.grey.shade50);
    final Color hintColor = theme.hintColor;
    final Color borderColor = theme.dividerColor;
    final Color focusedBorderColor = headerColor; // Use header color for focus
    final Color errorBorderColor = theme.colorScheme.error;

    // Use await to get the result from showDialog
    return await showDialog<String?>(
      context: bottomSheetContext, // Use context from bottom sheet
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: dialogBackgroundColor, // Use theme dialog background
          elevation: isDark ? 2 : 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              // Remove gradient, use solid theme color
              color: dialogBackgroundColor,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- Custom Header ---
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                    decoration: BoxDecoration(
                      color: headerColor, // Orange header
                    ),
                    child: Row(
                      children: [
                        Icon(Ionicons.close_circle_outline, // Reject icon
                            color: headerForegroundColor,
                            size: 20),
                        const SizedBox(width: 12),
                        // Title Text
                        Expanded(
                          child: Text(
                            'Reject Worker', // Title
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: headerForegroundColor,
                            ),
                          ),
                        ),
                        // Close button (acts as Cancel)
                        IconButton(
                          icon: Icon(Ionicons.close_outline,
                              color: headerForegroundColor),
                          iconSize: 22,
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                          tooltip: 'Cancel',
                          onPressed: () {
                            Navigator.of(dialogContext).pop(null);
                          },
                        ),
                      ],
                    ),
                  ),
                  // --- Content ---
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        24, 20, 24, 12), // Adjusted padding
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize:
                            MainAxisSize.min, // Make column take minimum space
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Please provide a reason for rejecting ${worker.fullName}:',
                            style: GoogleFonts.inter(
                              fontSize: 14.0,
                              color: contentTextColor, // Use theme text color
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: reasonController,
                            autofocus: true,
                            maxLines: 3,
                            style: GoogleFonts.inter(
                                color: contentTextColor,
                                fontSize: 14.0), // Use theme text color
                            decoration: InputDecoration(
                              hintText: 'Enter reason...',
                              hintStyle: GoogleFonts.inter(
                                  color: hintColor), // Use theme hint color
                              filled: true,
                              fillColor:
                                  inputFillColor, // Use theme input fill color
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                    color: borderColor,
                                    width: 1.0), // Use theme border color
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                    color: borderColor,
                                    width: 1.0), // Use theme border color
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                    color:
                                        focusedBorderColor, // Use specific focus color
                                    width: 1.5),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                    color: errorBorderColor,
                                    width: 1.0), // Use theme error color
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                    color: errorBorderColor,
                                    width: 1.5), // Use theme error color
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Reason cannot be empty';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  // --- Actions Section ---
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        24, 0, 24, 16), // Padding for actions
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: theme.textTheme.bodyMedium?.color
                                ?.withOpacity(
                                    0.7), // Use theme text color for cancel
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          onPressed: () {
                            Navigator.of(dialogContext).pop(null);
                          },
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                headerColor, // Keep specific reject button color
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            elevation: 2,
                          ),
                          child: Text(
                            'Submit Reject',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              final reason = reasonController.text.trim();
                              Navigator.of(dialogContext).pop(reason);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).whenComplete(() {
      // reasonController.dispose(); // Dispose controller
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get theme data
    // Use theme colors for TabBar
    final Color tabBarBackgroundColor =
        theme.appBarTheme.backgroundColor ?? theme.primaryColor;
    final Color tabBarForegroundColor =
        theme.appBarTheme.foregroundColor ?? theme.colorScheme.onPrimary;
    final Color indicatorColor = theme.indicatorColor;

    return DefaultTabController(
      length: 2, // Specify the number of tabs
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Use theme colors for TabBar container and properties
              Container(
                color:
                    tabBarBackgroundColor, // Use theme AppBar background color
                child: TabBar(
                  labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  unselectedLabelStyle: GoogleFonts.inter(),
                  labelColor:
                      tabBarForegroundColor, // Use theme AppBar foreground color
                  unselectedLabelColor: tabBarForegroundColor.withOpacity(0.7),
                  indicatorColor: indicatorColor, // Use theme indicator color
                  tabs: const [
                    Tab(text: 'Worker Details'),
                    Tab(text: 'Worker Requests'),
                  ],
                ),
              ),
              // Expanded TabBarView takes the remaining space
              Expanded(
                child: TabBarView(
                  children: [
                    // --- Tab 1: Worker Details List ---
                    _buildApprovedWorkersList(), // Changed function name for clarity
                    // --- Tab 2: Worker Requests ---
                    _buildWorkerRequestsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Renamed and modified to use FutureBuilder for approved workers
  Widget _buildApprovedWorkersList() {
    return RefreshIndicator(
      onRefresh: _refreshApprovedWorkers, // Use the correct refresh function
      child: FutureBuilder<List<Worker>>(
        future: _approvedWorkersFuture, // Use the future for approved workers
        builder: (context, snapshot) {
          // Loading state - Use SpinKit animation
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Replace CircularProgressIndicator with a SpinKit animation
            return Center(
              child: SpinKitFadingCircle(
                // Example SpinKit animation
                color: Theme.of(context).primaryColor,
                size: 50.0,
              ),
            );
          }
          // Error state
          else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Ionicons.cloud_offline_outline,
                        size: 60, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text('Error loading workers',
                        style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700]),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text('${snapshot.error}',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: Colors.grey[500]),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(Ionicons.refresh_outline, size: 18),
                      label: const Text('Retry'),
                      onPressed:
                          _refreshApprovedWorkers, // Use the correct refresh function
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white),
                    )
                  ],
                ),
              ),
            );
          }
          // Empty state
          else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Ionicons.people_outline,
                      size: 60,
                      color: Colors.grey[400]), // Icon for workers list
                  const SizedBox(height: 16),
                  Text('No approved workers found.',
                      style: GoogleFonts.inter(
                          fontSize: 16, color: Colors.grey[600])),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Ionicons.refresh_outline, size: 18),
                    label: const Text('Refresh'),
                    onPressed:
                        _refreshApprovedWorkers, // Use the correct refresh function
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white),
                  )
                ],
              ),
            );
          }

          // Data loaded successfully
          final approvedWorkers = snapshot.data!;
          return ListView.builder(
            padding:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
            itemCount: approvedWorkers.length,
            itemBuilder: (context, index) {
              final worker = approvedWorkers[index];
              // Use the existing _buildWorkerCard for displaying approved workers
              return _buildWorkerCard(worker);
            },
          );
        },
      ),
    );
  }

  // Updated widget for the second tab (PENDING requests) - remains largely the same
  Widget _buildWorkerRequestsTab() {
    return RefreshIndicator(
      onRefresh: _refreshWorkerRequests, // Correct refresh function
      child: FutureBuilder<List<Worker>>(
        future: _workerRequestsFuture, // Correct future
        builder: (context, snapshot) {
          // Loading state - Use SpinKit animation
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Replace CircularProgressIndicator with a SpinKit animation
            return Center(
              child: SpinKitFadingCircle(
                // Example SpinKit animation
                color: Theme.of(context).primaryColor,
                size: 50.0,
              ),
            );
          }
          // Error state
          else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Ionicons.cloud_offline_outline,
                        size: 60, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading requests',
                      style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}', // Display the actual error
                      style: GoogleFonts.inter(
                          fontSize: 13, color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(Ionicons.refresh_outline, size: 18),
                      label: const Text('Retry'),
                      onPressed:
                          _refreshWorkerRequests, // Correct refresh function
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    )
                  ],
                ),
              ),
            );
          }
          // Empty state
          else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                      Ionicons.documents_outline, // Different icon for requests
                      size: 60,
                      color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No pending worker requests found.',
                    style: GoogleFonts.inter(
                        fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Ionicons.refresh_outline, size: 18),
                    label: const Text('Refresh'),
                    onPressed:
                        _refreshWorkerRequests, // Correct refresh function
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  )
                ],
              ),
            );
          }

          // Data loaded successfully
          final requests = snapshot.data!;
          return ListView.builder(
            padding:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final workerRequest = requests[index];
              // Use the card specifically designed for requests
              return _buildWorkerRequestCard(workerRequest);
            },
          );
        },
      ),
    );
  }

  // Card for PENDING worker requests (Tab 2)
  Widget _buildWorkerRequestCard(Worker worker) {
    final theme = Theme.of(context);
    final initials =
        worker.firstName.isNotEmpty ? worker.firstName[0].toUpperCase() : '?';
    final avatarBackgroundColor = theme.primaryColor.withOpacity(0.1);
    final avatarTextColor = theme.primaryColor;
    final Color subtleTextColor =
        theme.textTheme.bodySmall?.color ?? Colors.grey.shade600;

    return Card(
      color: theme.cardColor, // Use theme card color instead of explicit white
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 1.0,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24, // Slightly smaller
              backgroundColor: avatarBackgroundColor,
              child: worker.profilePicUrl != null &&
                      worker.profilePicUrl!.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        worker.profilePicUrl!,
                        fit: BoxFit.cover,
                        width: 48,
                        height: 48,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                              child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null));
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Text(initials,
                              style: TextStyle(
                                  color: avatarTextColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16));
                        },
                      ),
                    )
                  : Text(initials,
                      style: TextStyle(
                          color: avatarTextColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
            ),
            const SizedBox(width: 12),
            // Name and Email Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    worker.fullName,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: theme
                          .textTheme.bodyLarge?.color, // Use theme text color
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    worker.email,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color:
                          subtleTextColor, // Use theme-based subtle text color
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Action Buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Review Button
                OutlinedButton(
                  onPressed: () {
                    _showReviewBottomSheet(context, worker);
                  },
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    'Review',
                    style: GoogleFonts.inter(
                        color: theme.brightness == Brightness.dark
                            ? Colors.white
                            : Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                        fontSize: 13),
                  ),
                ),
                const SizedBox(width: 8),
                // Accept Button
                ElevatedButton(
                  onPressed: () {
                    // Call the accept function directly
                    _acceptWorkerRequest(worker.id);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 1.5,
                  ),
                  child: Text(
                    'Accept',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // Function to show the review bottom sheet (for PENDING requests)
  void _showReviewBottomSheet(BuildContext context, Worker worker) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final initials =
        worker.firstName.isNotEmpty ? worker.firstName[0].toUpperCase() : '?';
    final avatarBackgroundColor = theme.primaryColor.withOpacity(0.1);
    final avatarTextColor = theme.primaryColor;
    final Color subtleTextColor = theme.textTheme.bodySmall?.color ??
        (isDark ? Colors.grey.shade400 : Colors.grey.shade600);
    final Color detailLabelColor =
        theme.textTheme.bodySmall?.color?.withOpacity(0.8) ??
            (isDark ? Colors.grey.shade400 : Colors.grey.shade500);
    final Color detailValueColor = theme.textTheme.bodyLarge?.color ??
        (isDark ? Colors.white : Colors.black87);
    final Color dividerColor = theme.dividerColor;
    final Color sheetBackgroundColor =
        theme.dialogBackgroundColor; // Use dialog background for consistency

    showModalBottomSheet(
      context: context, // Main context
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        // Explicitly name the builder context
        return DraggableScrollableSheet(
          initialChildSize: 0.6, // Start at 60% height
          minChildSize: 0.4, // Min height
          maxChildSize: 0.85, // Max height
          expand: false,
          builder: (_, controller) {
            return Container(
              decoration: BoxDecoration(
                // Use theme color
                color: sheetBackgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                border: isDark
                    ? Border.all(
                        color: Colors.white.withOpacity(0.1), width: 0.5)
                    : null,
              ),
              child: Stack(
                clipBehavior: Clip.none, // Allow avatar to overflow
                alignment: Alignment.topCenter,
                children: [
                  // Scrollable Content
                  ListView(
                    controller: controller, // Use the controller for scrolling
                    padding: const EdgeInsets.only(top: 45), // Space for avatar
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Column(
                          children: [
                            const SizedBox(height: 30), // Space below avatar
                            // Name and Title - Use theme text colors
                            Text(
                              worker.fullName,
                              style: GoogleFonts.outfit(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      detailValueColor), // Use theme text color
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              worker.email, // Or Job Title
                              style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  color:
                                      subtleTextColor), // Use theme subtle color
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),

                            // Action Buttons (Reject/Accept) - Styles remain specific
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                OutlinedButton(
                                  onPressed: () async {
                                    // Make onPressed async
                                    // Await the result from the dialog
                                    final String? reason =
                                        await _showRejectReasonDialog(
                                            bottomSheetContext, worker);

                                    // Check if a reason was returned (Submit was pressed)
                                    if (reason != null) {
                                      // Pop the bottom sheet *first* if it's still mounted
                                      if (bottomSheetContext.mounted) {
                                        Navigator.pop(bottomSheetContext);
                                        // Add a very short delay to allow the tree to settle
                                        await Future.delayed(
                                            const Duration(milliseconds: 50));
                                      }
                                      // THEN call the reject function
                                      // Check if the main screen state is still mounted before calling reject
                                      if (mounted) {
                                        _rejectWorkerRequest(worker.id, reason);
                                      }
                                    }
                                    // If reason is null, the dialog was cancelled, do nothing further here.
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 30, vertical: 12),
                                    side:
                                        BorderSide(color: Colors.red.shade200),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                  ),
                                  child: Text(
                                    'Reject',
                                    style: GoogleFonts.outfit(
                                        color: Colors.red.shade700,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                ElevatedButton(
                                  onPressed: () async {
                                    // Make async
                                    // Pop bottom sheet first before accepting
                                    Navigator.pop(bottomSheetContext);
                                    // Add a short delay
                                    await Future.delayed(
                                        const Duration(milliseconds: 50));
                                    // Call the accept function if mounted
                                    if (mounted) {
                                      _acceptWorkerRequest(worker.id);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade600,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 30, vertical: 13),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    elevation: 2,
                                  ),
                                  child: Text(
                                    'Accept',
                                    style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Divider(
                                color: dividerColor), // Use theme divider color
                            const SizedBox(height: 16),

                            // Additional Details Section - Use theme text colors
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    left: 4.0,
                                    bottom: 8.0), // Add padding for title
                                child: Text(
                                  'Details', // Section Title
                                  style: GoogleFonts.outfit(
                                      fontSize: 17, // Slightly larger title
                                      fontWeight: FontWeight.w600,
                                      color:
                                          detailValueColor), // Use theme text color
                                ),
                              ),
                            ),
                            // Use updated _buildRequestDetailRow which returns ListTile
                            _buildRequestDetailRow(
                                Ionicons.call_outline,
                                'Phone',
                                worker.phone ?? 'N/A',
                                detailLabelColor, // Use theme label color
                                detailValueColor), // Use theme value color
                            _buildRequestDetailRow(
                                Ionicons.home_outline,
                                'Address',
                                worker.address ?? 'N/A',
                                detailLabelColor, // Use theme label color
                                detailValueColor), // Use theme value color
                            _buildRequestDetailRow(
                                Ionicons.shield_checkmark_outline,
                                'Aadhaar',
                                worker.adhaar ?? 'N/A',
                                detailLabelColor, // Use theme label color
                                detailValueColor), // Use theme value color
                            if (worker.createdAt != null)
                              _buildRequestDetailRow(
                                  Ionicons.calendar_outline,
                                  'Requested On',
                                  DateFormat.yMMMd()
                                      .add_jm()
                                      .format(worker.createdAt!),
                                  detailLabelColor, // Use theme label color
                                  detailValueColor), // Use theme value color
                            const SizedBox(height: 20), // Bottom padding
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Overlapping Avatar
                  Positioned(
                    top: -35, // Position half above the sheet
                    child: CircleAvatar(
                      radius: 45, // Larger avatar
                      backgroundColor: Colors.white, // White border effect
                      child: CircleAvatar(
                        radius: 42, // Slightly smaller inner avatar
                        backgroundColor: avatarBackgroundColor,
                        child: worker.profilePicUrl != null &&
                                worker.profilePicUrl!.isNotEmpty
                            ? ClipOval(
                                child: Image.network(
                                  worker.profilePicUrl!,
                                  fit: BoxFit.cover,
                                  width: 80,
                                  height: 80,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Center(
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2.0));
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Text(initials,
                                        style: TextStyle(
                                            color: avatarTextColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 24));
                                  },
                                ),
                              )
                            : Text(initials,
                                style: TextStyle(
                                    color: avatarTextColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24)),
                      ),
                    ),
                  ),

                  // Close button at top right corner
                  Positioned(
                    top: 10,
                    right: 10,
                    child: IconButton(
                      icon: Icon(Ionicons.close_circle,
                          color: theme.iconTheme.color
                              ?.withOpacity(0.5)), // Use theme icon color
                      iconSize: 28,
                      onPressed: () => Navigator.pop(bottomSheetContext),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Helper widget for detail rows inside the bottom sheet - Now uses ListTile
  Widget _buildRequestDetailRow(IconData icon, String label, String value,
      Color iconColor, Color valueColor) {
    final theme = Theme.of(context); // Get theme
    final Color labelColor = theme.textTheme.bodySmall?.color ??
        Colors.grey.shade600; // Use theme label color

    return ListTile(
      dense: true, // Make tile more compact
      contentPadding: const EdgeInsets.symmetric(
          vertical: 0, horizontal: 4.0), // Adjust padding
      leading: Icon(icon,
          size: 20,
          color: labelColor.withOpacity(0.8)), // Use theme label color for icon
      title: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 12.5, // Label font size
          color: labelColor, // Use theme label color
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Padding(
        padding:
            const EdgeInsets.only(top: 2.0), // Space between label and value
        child: Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 14.5, // Value font size
            color: valueColor, // Use theme value color passed in
            fontWeight: FontWeight.w500, // Medium weight for value
            height: 1.3,
          ),
        ),
      ),
    );
  }

  // Card for APPROVED workers (Tab 1) - This is the existing _buildWorkerCard
  Widget _buildWorkerCard(Worker worker) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    // Define colors explicitly for dark/light mode for better contrast
    final Color cardIconColor =
        isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final Color cardDetailTextColor =
        isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final Color popupMenuIconColor =
        isDark ? Colors.grey.shade400 : Colors.grey.shade500;

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: theme.cardColor, // Use theme card color
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.brightness == Brightness.dark
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? Colors.white.withOpacity(0.05) // Subtle border in dark mode
              : Colors.grey
                  .withOpacity(0.05), // Very subtle border in light mode
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _viewWorkerDetails(worker),
          child: Padding(
            padding: const EdgeInsets.all(16.0), // Consistent padding
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.center, // Center items vertically
              children: [
                CircleAvatar(
                  radius: 30, // Larger avatar
                  backgroundColor: theme.brightness == Brightness.dark
                      ? theme.primaryColor.withOpacity(0.6)
                      : Colors.grey.shade100,
                  backgroundImage: worker.profilePicUrl != null
                      ? NetworkImage(worker.profilePicUrl!)
                      : null,
                  child: worker.profilePicUrl == null
                      ? Icon(Ionicons.person_circle_outline, // Different icon
                          color: isDark
                              ? Colors.white.withOpacity(0.5)
                              : Colors.grey.shade400,
                          size: 32)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${worker.firstName} ${worker.lastName}',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 16.5,
                          color: theme.textTheme.bodyLarge
                              ?.color, // Use theme text color
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6), // More space below name
                      Row(
                        // Icon and Email
                        children: [
                          Icon(Ionicons.mail_outline,
                              size: 15,
                              color: cardIconColor), // Use explicit color
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              worker.email,
                              style: GoogleFonts.inter(
                                fontSize: 13.5, // Slightly larger detail text
                                color:
                                    cardDetailTextColor, // Use explicit color
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4), // Spacing between email/phone
                      Row(
                        // Icon and Phone
                        children: [
                          Icon(Ionicons.call_outline,
                              size: 15,
                              color: cardIconColor), // Use explicit color
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              worker.phone ?? 'N/A',
                              style: GoogleFonts.inter(
                                fontSize: 13.5, // Slightly larger detail text
                                color:
                                    cardDetailTextColor, // Use explicit color
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8), // Space before menu button

                // Action Buttons - PopupMenu remains the same
                PopupMenuButton<String>(
                  icon: Icon(Ionicons.ellipsis_vertical,
                      color: popupMenuIconColor), // Use explicit color
                  tooltip: "Actions",
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  offset: Offset(0, 40), // Corrected offset property
                  color: theme.popupMenuTheme.color ??
                      theme.cardColor, // Use theme popup color
                  itemBuilder:
                      (BuildContext context) => // Corrected itemBuilder syntax
                          <PopupMenuEntry<String>>[
                    _buildPopupMenuItem(
                      context: context,
                      value: 'view', // Corrected value property
                      icon: Ionicons.eye_outline, // Corrected icon property
                      text: 'View Details',
                    ),
                    _buildPopupMenuItem(
                      context: context,
                      value: 'edit', // Corrected value property
                      icon: Ionicons.create_outline, // Corrected icon property
                      text: 'Edit Worker',
                    ),
                    const PopupMenuDivider(),
                    _buildPopupMenuItem(
                      context: context,
                      value: 'delete', // Corrected value property
                      icon: Ionicons.trash_outline, // Corrected icon property
                      text: 'Delete Worker', // Corrected text property
                      color: Colors.red[700], // Corrected color property
                    ),
                  ],
                  onSelected: (String result) {
                    switch (result) {
                      case 'view':
                        _viewWorkerDetails(worker);
                        break;
                      case 'edit':
                        _editWorker(worker);
                        break;
                      case 'delete':
                        _deleteWorker(worker);
                        break;
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper to build styled PopupMenuItems - Updated to use theme text color
  PopupMenuItem<String> _buildPopupMenuItem({
    required BuildContext context, // Need context for Theme
    required String value,
    required IconData icon,
    required String text,
    Color? color, // Optional color for icon and text (e.g., for delete)
  }) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    // Use provided color if available, otherwise use theme's default text color for popups,
    // ensuring a fallback for dark/light mode.
    final itemColor = color ??
        theme.popupMenuTheme.textStyle?.color ??
        (isDark ? Colors.grey.shade200 : Colors.grey.shade800);

    return PopupMenuItem<String>(
      value: value,
      padding: const EdgeInsets.symmetric(
          horizontal: 16.0, vertical: 8.0), // Adjust padding
      child: Row(
        children: [
          Icon(icon, size: 20, color: itemColor), // Use determined item color
          const SizedBox(width: 12),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: itemColor, // Use determined item color
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _viewWorkerDetails(Worker worker) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color primaryColor = theme.colorScheme.primary;
    final Color subtleTextColor = theme.textTheme.bodySmall?.color ??
        (isDark ? Colors.grey.shade400 : Colors.grey.shade600);
    final Color detailLabelColor =
        theme.textTheme.bodySmall?.color?.withOpacity(0.8) ??
            (isDark ? Colors.grey.shade400 : Colors.grey.shade500);
    final Color detailValueColor = theme.textTheme.bodyLarge?.color ??
        (isDark ? Colors.white : Colors.black87);
    final Color avatarBackgroundColor = primaryColor.withOpacity(0.1);
    final Color avatarTextColor = primaryColor;
    final Color dividerColor = theme.dividerColor;
    final Color sheetBackgroundColor =
        theme.dialogBackgroundColor; // Use dialog background for consistency
    final initials =
        worker.firstName.isNotEmpty ? worker.firstName[0].toUpperCase() : '?';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65, // Start at 65% of screen height
          minChildSize: 0.4, // Min size when dragged down
          maxChildSize: 0.9, // Nearly full screen when dragged up
          expand: false,
          builder: (_, controller) {
            return Container(
              decoration: BoxDecoration(
                // Use theme color
                color: sheetBackgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                border: isDark
                    ? Border.all(
                        color: Colors.white.withOpacity(0.1), width: 0.5)
                    : null,
              ),
              child: Stack(
                clipBehavior: Clip.none, // Allow avatar to overflow
                alignment: Alignment.topCenter,
                children: [
                  // Scrollable Content
                  ListView(
                    controller: controller, // Use the provided controller
                    padding: const EdgeInsets.only(top: 45), // Space for avatar
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Column(
                          children: [
                            const SizedBox(height: 30), // Space below avatar
                            // Name and Email - Use theme colors
                            Text(
                              worker.fullName,
                              style: GoogleFonts.outfit(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      detailValueColor), // Use theme text color
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              worker.email,
                              style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  color:
                                      subtleTextColor), // Use theme subtle color
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            Divider(
                                color: dividerColor), // Use theme divider color
                            const SizedBox(height: 16),

                            // Details Section - Use theme colors
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    left: 4.0, bottom: 8.0),
                                child: Text(
                                  'Details',
                                  style: GoogleFonts.outfit(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          detailValueColor), // Use theme text color
                                ),
                              ),
                            ),

                            // Worker Details - using _buildRequestDetailRow for consistency
                            _buildRequestDetailRow(
                                Ionicons.id_card_outline,
                                'Worker ID',
                                worker.id.toString(),
                                detailLabelColor, // Use theme label color
                                detailValueColor), // Use theme value color
                            _buildRequestDetailRow(
                                Ionicons.mail_outline,
                                'Email',
                                worker.email,
                                detailLabelColor, // Use theme label color
                                detailValueColor), // Use theme value color
                            _buildRequestDetailRow(
                                Ionicons.call_outline,
                                'Phone',
                                worker.phone ?? 'N/A',
                                detailLabelColor, // Use theme label color
                                detailValueColor), // Use theme value color
                            _buildRequestDetailRow(
                                Ionicons.home_outline,
                                'Address',
                                worker.address ?? 'N/A',
                                detailLabelColor, // Use theme label color
                                detailValueColor), // Use theme value color
                            _buildRequestDetailRow(
                                Ionicons.shield_checkmark_outline,
                                'Aadhaar',
                                worker.adhaar ?? 'N/A',
                                detailLabelColor, // Use theme label color
                                detailValueColor), // Use theme value color
                            if (worker.createdAt != null)
                              _buildRequestDetailRow(
                                  Ionicons.calendar_outline,
                                  'Joined On',
                                  DateFormat.yMMMd().format(worker.createdAt!),
                                  detailLabelColor, // Use theme label color
                                  detailValueColor), // Use theme value color

                            const SizedBox(height: 30), // Bottom padding
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Overlapping Avatar
                  Positioned(
                    top: -35, // Position half above the sheet
                    child: CircleAvatar(
                      radius: 45, // Larger avatar
                      backgroundColor: Colors.white, // White border effect
                      child: CircleAvatar(
                        radius: 42, // Slightly smaller inner avatar
                        backgroundColor: avatarBackgroundColor,
                        child: worker.profilePicUrl != null &&
                                worker.profilePicUrl!.isNotEmpty
                            ? ClipOval(
                                child: Image.network(
                                  worker.profilePicUrl!,
                                  fit: BoxFit.cover,
                                  width: 80,
                                  height: 80,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Center(
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2.0));
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Text(initials,
                                        style: TextStyle(
                                            color: avatarTextColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 24));
                                  },
                                ),
                              )
                            : Text(initials,
                                style: TextStyle(
                                    color: avatarTextColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- API Call for Updating Worker ---
  Future<bool> _updateWorkerApi(int workerId, Map<String, dynamic> data) async {
    final url = Uri.parse('$_baseApiUrl/workers/$workerId/update/');
    try {
      final response = await http.put(
        // Or http.patch
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) {
        return true;
      } else {
        print(
            'Failed to update worker: ${response.statusCode} ${response.body}');
        Fluttertoast.showToast(
            msg: 'Failed to update worker: ${response.statusCode}',
            backgroundColor: Colors.red);
        return false;
      }
    } catch (e) {
      print('Error updating worker: $e');
      Fluttertoast.showToast(
          msg: 'Error updating worker.', backgroundColor: Colors.red);
      return false;
    }
  }

  // --- API Call for Deleting Worker ---
  Future<bool> _deleteWorkerApi(int workerId) async {
    final url = Uri.parse('$_baseApiUrl/workers/$workerId/delete/');
    try {
      final response = await http.delete(url);
      if (response.statusCode == 200 || response.statusCode == 204) {
        // Handle 204 No Content
        return true;
      } else {
        print(
            'Failed to delete worker: ${response.statusCode} ${response.body}');
        Fluttertoast.showToast(
            msg: 'Failed to delete worker: ${response.statusCode}',
            backgroundColor: Colors.red);
        return false;
      }
    } catch (e) {
      print('Error deleting worker: $e');
      Fluttertoast.showToast(
          msg: 'Error deleting worker.', backgroundColor: Colors.red);
      return false;
    }
  }

  void _editWorker(Worker worker) {
    // Controllers for text fields
    final firstNameController = TextEditingController(text: worker.firstName);
    final lastNameController = TextEditingController(text: worker.lastName);
    final emailController = TextEditingController(text: worker.email);
    final phoneController = TextEditingController(text: worker.phone);
    final addressController = TextEditingController(text: worker.address);
    // Adhaar and ID are likely not editable, so we omit them or display them as read-only

    // Use theme colors
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color headerColor =
        Colors.pink.shade400; // Keep specific header color
    final Color headerForegroundColor = Colors.white;
    final Color dialogBackgroundColor = theme.dialogBackgroundColor;
    final Color contentTextColor = theme.textTheme.bodyLarge?.color ??
        (isDark ? Colors.white : Colors.black87);
    final Color iconColor =
        theme.iconTheme.color?.withOpacity(0.7) ?? Colors.grey.shade500;
    final Color dividerColor = theme.dividerColor;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: dialogBackgroundColor, // Use theme dialog background
          elevation: isDark ? 2 : 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              // Remove gradient, use solid theme color
              color: dialogBackgroundColor,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- Custom Header ---
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                    decoration: BoxDecoration(
                      color: headerColor, // Keep specific header color
                    ),
                    child: Row(
                      children: [
                        // Leading Avatar (optional, could be removed for edit)
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.white.withOpacity(0.8),
                          backgroundImage: worker.profilePicUrl != null
                              ? NetworkImage(worker.profilePicUrl!)
                              : null,
                          child: worker.profilePicUrl == null
                              ? Icon(
                                  Ionicons.create_outline, // Edit icon
                                  color:
                                      headerForegroundColor.computeLuminance() >
                                              0.8
                                          ? Colors.black54
                                          : Colors.white70,
                                  size: 18,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        // Title Text
                        Expanded(
                          child: Text(
                            'Edit Worker', // Changed Title
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: headerForegroundColor,
                            ),
                          ),
                        ),
                        // Close button
                        IconButton(
                          icon: Icon(Ionicons.close_outline,
                              color: headerForegroundColor),
                          iconSize: 22,
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                          tooltip: 'Cancel',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  // --- Scrollable Form Content ---
                  Flexible(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Use themed text field helper
                            _buildThemedTextField(context, firstNameController,
                                'First Name', Ionicons.person_outline),
                            const SizedBox(height: 12),
                            _buildThemedTextField(
                                context, lastNameController, 'Last Name', null),
                            const SizedBox(height: 12),
                            Divider(
                                color: dividerColor,
                                height: 20), // Use theme divider color
                            _buildThemedTextField(context, emailController,
                                'Email', Ionicons.mail_outline),
                            const SizedBox(height: 12),
                            _buildThemedTextField(context, phoneController,
                                'Phone', Ionicons.call_outline,
                                keyboardType: TextInputType.phone),
                            const SizedBox(height: 12),
                            _buildThemedTextField(context, addressController,
                                'Address', Ionicons.home_outline,
                                maxLines: 3),
                            const SizedBox(height: 20),

                            // Actions Section - Use theme colors
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  style: TextButton.styleFrom(
                                    foregroundColor: theme
                                        .textTheme.bodyMedium?.color
                                        ?.withOpacity(
                                            0.7), // Use theme text color for cancel
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 18, vertical: 10),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: Text(
                                    'Cancel',
                                    style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14),
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        headerColor, // Keep specific save button color
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 18, vertical: 10),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                    elevation: 2,
                                  ),
                                  child: Text(
                                    'Save Changes',
                                    style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14),
                                  ),
                                  onPressed: () async {
                                    // 1. Prepare data for API
                                    final updateData = {
                                      'first_name': firstNameController.text,
                                      'last_name': lastNameController.text,
                                      'email': emailController
                                          .text, // Be cautious if allowing email change
                                      'phone': phoneController.text,
                                      'address': addressController.text,
                                      // Add other fields if they are editable
                                    };

                                    // 2. Call API to update backend
                                    bool success = await _updateWorkerApi(
                                        worker.id, updateData);

                                    if (success && mounted) {
                                      // 3. Update local state ONLY if API call was successful
                                      final updatedWorker = Worker(
                                        id: worker.id,
                                        firstName: firstNameController.text,
                                        lastName: lastNameController.text,
                                        email: emailController.text,
                                        phone: phoneController.text,
                                        address: addressController.text,
                                        adhaar: worker.adhaar,
                                        profilePicUrl: worker.profilePicUrl,
                                        approvalStatus: worker
                                            .approvalStatus, // Keep status
                                        createdAt: worker
                                            .createdAt, // Keep original date
                                      );

                                      // Get current list, update it, and refresh the future
                                      try {
                                        List<Worker> currentWorkers =
                                            await _approvedWorkersFuture;
                                        int index = currentWorkers.indexWhere(
                                            (w) => w.id == worker.id);
                                        if (index != -1) {
                                          List<Worker> newWorkers =
                                              List.from(currentWorkers);
                                          newWorkers[index] = updatedWorker;
                                          setState(() {
                                            _approvedWorkersFuture =
                                                Future.value(newWorkers);
                                          });
                                        } else {
                                          // Optionally refresh from server if worker not found locally
                                          _refreshApprovedWorkers();
                                        }
                                      } catch (e) {
                                        print(
                                            "Error updating local future: $e");
                                        _refreshApprovedWorkers(); // Refresh from server on error
                                      }

                                      Navigator.of(context)
                                          .pop(); // Close dialog

                                      Fluttertoast.showToast(
                                          msg:
                                              "${updatedWorker.firstName} updated successfully",
                                          backgroundColor:
                                              Colors.green.shade600,
                                          textColor: Colors.white);
                                    } else if (!success && mounted) {
                                      // API call failed, maybe show specific error from API if available
                                      Fluttertoast.showToast(
                                          msg:
                                              "Update failed. Please try again.",
                                          backgroundColor: Colors.red);
                                    }
                                  },
                                ),
                              ],
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
    ).whenComplete(() {
      // ... (Dispose controllers if needed, though handled by State) ...
    });
  }

  // Helper widget for creating styled TextFields - Updated to use theme and specific dark mode colors
  Widget _buildThemedTextField(BuildContext context,
      TextEditingController controller, String label, IconData? icon,
      {int maxLines = 1, TextInputType? keyboardType}) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    // Define colors based on theme, matching the screenshot for dark mode
    final Color fillColor = isDark
        ? Colors.grey.shade700.withOpacity(0.5)
        : Colors.grey.shade100.withOpacity(0.5);
    final Color textColor = isDark
        ? Colors.white
        : theme.textTheme.bodyLarge?.color ?? Colors.black87;
    final Color labelColor =
        isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final Color iconColor =
        isDark ? Colors.grey.shade400 : Colors.grey.shade500;
    final Color borderColor =
        isDark ? Colors.grey.shade600 : Colors.grey.shade300;
    final Color focusedBorderColor = theme.primaryColor;

    return TextField(
      controller: controller,
      style: GoogleFonts.inter(color: textColor, fontSize: 14.5),
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: labelColor, fontSize: 13),
        prefixIcon:
            icon != null ? Icon(icon, color: iconColor, size: 20) : null,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14.0, horizontal: 12.0),
        filled: true,
        fillColor: fillColor, // Use defined fill color
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
              color: borderColor, width: 1.0), // Use defined border color
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
              color: borderColor, width: 1.0), // Use defined border color
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
              color: focusedBorderColor,
              width: 1.5), // Use theme primary for focus
        ),
      ),
    );
  }

  void _deleteWorker(Worker worker) {
    // Use theme colors
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color headerColor = Colors.red.shade700; // Keep specific delete color
    final Color headerForegroundColor = Colors.white;
    final Color dialogBackgroundColor = theme.dialogBackgroundColor;
    final Color contentTextColor = theme.textTheme.bodyLarge?.color ??
        (isDark ? Colors.white70 : Colors.grey.shade800);

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: dialogBackgroundColor, // Use theme dialog background
          elevation: isDark ? 2 : 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              // Remove gradient, use solid theme color
              color: dialogBackgroundColor,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- Custom Header ---
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                    decoration: BoxDecoration(
                      color: headerColor, // Red header
                    ),
                    child: Row(
                      children: [
                        Icon(Ionicons.warning_outline,
                            color: headerForegroundColor, size: 20),
                        const SizedBox(width: 12),
                        // Title Text
                        Expanded(
                          child: Text(
                            'Confirm Deletion', // Title
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: headerForegroundColor,
                            ),
                          ),
                        ),
                        // Close button (acts as Cancel)
                        IconButton(
                          icon: Icon(Ionicons.close_outline,
                              color: headerForegroundColor),
                          iconSize: 22,
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                          tooltip: 'Cancel',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  // --- Content ---
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        24, 20, 24, 20), // Adjusted padding
                    child: Text(
                      'Are you sure you want to delete ${worker.firstName} ${worker.lastName}? This action cannot be undone.',
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        color: contentTextColor, // Use theme text color
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // --- Actions Section ---
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        24, 0, 24, 16), // Padding for actions
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: theme.textTheme.bodyMedium?.color
                                ?.withOpacity(
                                    0.7), // Use theme text color for cancel
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                headerColor, // Keep specific delete button color
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            elevation: 2,
                          ),
                          child: Text(
                            'Delete',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          onPressed: () async {
                            // 1. Call API to delete from backend
                            bool success = await _deleteWorkerApi(worker.id);

                            if (success && mounted) {
                              // 2. Update local state ONLY if API call was successful
                              try {
                                List<Worker> currentWorkers =
                                    await _approvedWorkersFuture;
                                List<Worker> newWorkers = currentWorkers
                                    .where((w) => w.id != worker.id)
                                    .toList();
                                setState(() {
                                  _approvedWorkersFuture =
                                      Future.value(newWorkers);
                                });
                              } catch (e) {
                                print(
                                    "Error updating local future after delete: $e");
                                _refreshApprovedWorkers(); // Refresh from server on error
                              }

                              Navigator.of(context)
                                  .pop(); // Close confirmation dialog

                              Fluttertoast.showToast(
                                  msg:
                                      "${worker.firstName} deleted successfully",
                                  backgroundColor: Colors.red.shade600,
                                  textColor: Colors.white);
                            } else if (!success && mounted) {
                              // API call failed
                              Fluttertoast.showToast(
                                  msg: "Deletion failed. Please try again.",
                                  backgroundColor: Colors.red);
                              Navigator.of(context)
                                  .pop(); // Close confirmation dialog anyway
                            }
                          },
                        ),
                      ],
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
}
