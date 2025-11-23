import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ionicons/ionicons.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:attendance_tracking/config/api_config.dart';

class MyJobsView extends StatefulWidget {
  final String? userId;

  const MyJobsView({super.key, this.userId});

  @override
  State<MyJobsView> createState() => _MyJobsViewState();
}

class _MyJobsViewState extends State<MyJobsView> {
  Future<List<Map<String, dynamic>>>? _jobsFuture;
  List<Map<String, dynamic>> _allJobs = [];
  List<Map<String, dynamic>> _filteredJobs = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadJobs();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase().trim();
      _filterJobs();
    });
  }

  void _filterJobs() {
    if (_searchQuery.isEmpty) {
      _filteredJobs = List.from(_allJobs);
    } else {
      _filteredJobs = _allJobs.where((job) {
        final title = (job['title'] ?? '').toString().toLowerCase();
        final status = (job['status'] ?? '').toString().toLowerCase();
        final description = (job['description'] ?? '').toString().toLowerCase();
        final address = (job['address'] ?? '').toString().toLowerCase();
        final jobType = (job['job_type'] ?? '').toString().toLowerCase();
        final workEnvironment = (job['work_environment'] ?? '')
            .toString()
            .toLowerCase();
        final contractorName = job['contractor'] != null
            ? (job['contractor']['name'] ?? '').toString().toLowerCase()
            : '';
        final contractorEmail = job['contractor'] != null
            ? (job['contractor']['email'] ?? '').toString().toLowerCase()
            : '';
        final workerName = job['worker'] != null
            ? '${job['worker']['first_name'] ?? ''} ${job['worker']['last_name'] ?? ''}'
                  .toLowerCase()
            : '';

        return title.contains(_searchQuery) ||
            status.contains(_searchQuery) ||
            description.contains(_searchQuery) ||
            address.contains(_searchQuery) ||
            jobType.contains(_searchQuery) ||
            workEnvironment.contains(_searchQuery) ||
            contractorName.contains(_searchQuery) ||
            contractorEmail.contains(_searchQuery) ||
            workerName.contains(_searchQuery);
      }).toList();
    }
  }

  void _loadJobs() {
    setState(() {
      _jobsFuture = _fetchUserJobs();
    });
  }

  Future<void> _handleRefresh() async {
    _loadJobs();
    // Wait for the future to complete
    if (_jobsFuture != null) {
      await _jobsFuture!;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchUserJobs() async {
    if (widget.userId == null) {
      print('User ID is null, returning empty list');
      return [];
    }

    try {
      print('Fetching jobs for user: ${widget.userId}');
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/jobs/user/${widget.userId}/'),
        headers: {'Accept': 'application/json'},
      );

      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> jobsData = json.decode(response.body);
        final List<Map<String, dynamic>> jobs = jobsData.map((job) {
          return {
            'id': job['id']?.toString() ?? '',
            'title': job['title']?.toString() ?? 'No Title',
            'description': job['description']?.toString() ?? 'No Description',
            'address': job['address']?.toString() ?? 'No Address',
            'job_type': job['job_type']?.toString() ?? 'Unknown',
            'work_environment':
                job['work_environment']?.toString() ?? 'Unknown',
            'status': job['status']?.toString() ?? 'Pending',
            'contractor': job['contractor'] != null
                ? {
                    'id': job['contractor']['id']?.toString() ?? '',
                    'name': job['contractor']['name']?.toString() ?? 'Unknown',
                    'email': job['contractor']['email']?.toString() ?? '',
                  }
                : null,
            'worker': job['worker'] != null
                ? {
                    'id': job['worker']['id']?.toString() ?? '',
                    'first_name': job['worker']['first_name']?.toString() ?? '',
                    'last_name': job['worker']['last_name']?.toString() ?? '',
                    'email': job['worker']['email']?.toString() ?? '',
                    'phone': job['worker']['phone']?.toString() ?? '',
                    'profile_pic_url': job['worker']['profile_pic_url']
                        ?.toString(),
                  }
                : null,
            'job_posted_date': job['job_posted_date']?.toString() ?? '',
          };
        }).toList();

        print('Successfully parsed ${jobs.length} jobs');

        // Update all jobs and filtered jobs - MOVED OUTSIDE setState
        _allJobs = jobs;
        _filterJobs();

        return jobs;
      } else {
        print('Failed to fetch jobs: ${response.statusCode}');
        setState(() {
          _allJobs = [];
          _filteredJobs = [];
        });
        return [];
      }
    } catch (e) {
      print('Error fetching user jobs: $e');
      setState(() {
        _allJobs = [];
        _filteredJobs = [];
      });
      return [];
    }
  }

  Future<void> _editJob(Map<String, dynamic> job) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => EditJobDialog(job: job, userId: widget.userId!),
    );

    if (result != null) {
      _loadJobs(); // Refresh the jobs list
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Job updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _deleteJob(Map<String, dynamic> job) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Job',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete this job?',
              style: GoogleFonts.outfit(),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job['title'] ?? 'No Title',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      color: Colors.red[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    job['description'] ?? 'No Description',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.red[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This action cannot be undone.',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: GoogleFonts.outfit()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await http.delete(
          Uri.parse(
            '${ApiConfig.baseUrl}/api/jobs/user/${job['id']}/delete/?user_id=${widget.userId}',
          ),
          headers: {'Accept': 'application/json'},
        );

        if (response.statusCode == 200) {
          _loadJobs(); // Refresh the jobs list
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Job deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          final errorData = json.decode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorData['error'] ?? 'Failed to delete job'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting job: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Jobs',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 16),

            // Search Bar
            _buildSearchBar(theme, isDark),
            const SizedBox(height: 16),

            // Search Results Summary
            if (_searchQuery.isNotEmpty) _buildSearchSummary(theme),

            // Show filtered jobs instead of snapshot data
            _filteredJobs.isEmpty && _searchQuery.isNotEmpty
                ? _buildNoSearchResults()
                : _allJobs.isEmpty
                ? FutureBuilder<List<Map<String, dynamic>>>(
                    future: _jobsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: SpinKitFadingCircle(
                              color: Colors.grey,
                              size: 50.0,
                            ),
                          ),
                        );
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            children: [
                              Icon(
                                Ionicons.alert_circle_outline,
                                size: 48,
                                color: Colors.red[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Error loading jobs',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  color: Colors.red[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Pull down to refresh',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        );
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return _buildEmptyState();
                      }
                      return const SizedBox.shrink(); // This should not be reached since we handle _filteredJobs above
                    },
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _filteredJobs.length,
                    itemBuilder: (context, index) {
                      final job = _filteredJobs[index];
                      return _buildJobCard(job, theme, isDark);
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search jobs by name, status, contractor, location...',
          hintStyle: GoogleFonts.outfit(
            color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
          ),
          prefixIcon: Icon(
            Ionicons.search_outline,
            color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Ionicons.close_outline,
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                    size: 20,
                  ),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        style: GoogleFonts.outfit(color: theme.textTheme.bodyLarge?.color),
      ),
    );
  }

  Widget _buildSearchSummary(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Ionicons.filter_outline, size: 16, color: theme.primaryColor),
          const SizedBox(width: 8),
          Text(
            'Found ${_filteredJobs.length} job${_filteredJobs.length != 1 ? 's' : ''} for "${_searchQuery}"',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: theme.textTheme.bodySmall?.color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSearchResults() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Ionicons.search_outline, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No jobs found',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching with different keywords',
            style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () {
              _searchController.clear();
            },
            icon: Icon(
              Ionicons.refresh_outline,
              size: 18,
              color: Colors.grey[600],
            ),
            label: Text(
              'Clear Search',
              style: GoogleFonts.outfit(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Ionicons.briefcase_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No jobs found',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pull down to refresh or post your first job',
            style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job, ThemeData theme, bool isDark) {
    // Get status color based on job status
    Color getStatusColor(String status) {
      switch (status.toLowerCase()) {
        case 'pending':
          return Colors.orange;
        case 'in progress':
          return Colors.blue;
        case 'completed':
          return Colors.green;
        case 'cancelled':
          return Colors.red;
        default:
          return Colors.grey;
      }
    }

    final String workerName = job['worker'] != null
        ? '${job['worker']['first_name'] ?? ''} ${job['worker']['last_name'] ?? ''}'
              .trim()
        : '';

    final String contractorName = job['contractor'] != null
        ? job['contractor']['name'] ?? 'Unknown Contractor'
        : 'No Contractor';

    final String contractorEmail = job['contractor'] != null
        ? job['contractor']['email'] ?? ''
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 20.0),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section with Job Title and Status (removed action buttons)
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16.0),
                topRight: Radius.circular(16.0),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Icon(
                    Ionicons.briefcase_outline,
                    color: isDark
                        ? Colors.white.withOpacity(0.8)
                        : theme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job['title'] ?? 'No Title',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Ionicons.time_outline,
                            size: 14,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatJobDate(job['job_posted_date'] ?? ''),
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Status Badge only
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: getStatusColor(job['status'] ?? 'pending'),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: getStatusColor(
                          job['status'] ?? 'pending',
                        ).withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    job['status'] ?? 'Pending',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content Section
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description
                Text(
                  job['description'] ?? 'No Description',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: theme.textTheme.bodyMedium?.color,
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),

                // Location
                Row(
                  children: [
                    Icon(
                      Ionicons.location_outline,
                      size: 16,
                      color: theme.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        job['address'] ?? 'No Address',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Job Type and Environment Tags
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Ionicons.time_outline,
                            size: 12,
                            color: Colors.blue[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            job['job_type'] ?? 'Unknown',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Ionicons.business_outline,
                            size: 12,
                            color: Colors.green[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            job['work_environment'] ?? 'Unknown',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Contractor Details Section
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color.fromARGB(255, 26, 26, 26)
                        : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Ionicons.business_outline,
                            size: 16,
                            color: theme.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Contractor Details',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: isDark
                                ? Color.fromARGB(255, 21, 21, 21)
                                : Colors.grey[200],
                            child: Text(
                              contractorName.isNotEmpty
                                  ? contractorName[0].toUpperCase()
                                  : 'C',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white
                                    : theme.primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  contractorName,
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: theme.textTheme.bodyLarge?.color,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (contractorEmail.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    contractorEmail,
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      color: theme.textTheme.bodySmall?.color,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Worker Assignment Section
                if (workerName.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        color: Colors.green.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Ionicons.checkmark_circle_outline,
                              size: 16,
                              color: Colors.green[600],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Assigned Worker',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.green.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 18,
                                backgroundColor: Colors.green.withOpacity(0.1),
                                child: Text(
                                  workerName.isNotEmpty
                                      ? workerName[0].toUpperCase()
                                      : 'W',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    workerName,
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green[700],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (job['worker']?['email']?.isNotEmpty ==
                                      true) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      job['worker']['email'],
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        color: Colors.green[600],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (job['worker']?['phone']?.isNotEmpty == true)
                              IconButton(
                                onPressed: () {
                                  // Add phone call functionality
                                },
                                icon: Icon(
                                  Ionicons.call_outline,
                                  size: 18,
                                  color: Colors.green[600],
                                ),
                                tooltip: 'Call Worker',
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ] else if (job['status']?.toLowerCase() == 'pending') ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Ionicons.hourglass_outline,
                          size: 20,
                          color: Colors.orange[600],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Waiting for Assignment',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange[700],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'A worker will be assigned soon',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: Colors.orange[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Separator
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  isDark ? Colors.grey[700]! : Colors.grey[300]!,
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Bottom Action Buttons Section
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _editJob(job),
                    icon: Icon(
                      Ionicons.create_outline,
                      size: 18,
                      color: Colors.blue[600],
                    ),
                    label: Text(
                      'Edit Job',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w500,
                        color: Colors.blue[600],
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.blue[300]!),
                      backgroundColor: Colors.blue.withOpacity(0.05),
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
                    onPressed: () => _deleteJob(job),
                    icon: Icon(
                      Ionicons.trash_outline,
                      size: 18,
                      color: Colors.red[600],
                    ),
                    label: Text(
                      'Delete Job',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w500,
                        color: Colors.red[600],
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.red[300]!),
                      backgroundColor: Colors.red.withOpacity(0.05),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatJobDate(String dateString) {
    if (dateString.isEmpty) return 'Unknown date';

    try {
      final DateTime date = DateTime.parse(dateString);
      final DateTime now = DateTime.now();
      final Duration difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return 'Unknown date';
    }
  }
}

// Edit Job Dialog Widget
class EditJobDialog extends StatefulWidget {
  final Map<String, dynamic> job;
  final String userId;

  const EditJobDialog({super.key, required this.job, required this.userId});

  @override
  State<EditJobDialog> createState() => _EditJobDialogState();
}

class _EditJobDialogState extends State<EditJobDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _addressController;

  String _selectedJobType = 'Full Time';
  String _selectedWorkEnvironment = 'Indoor';
  List<Map<String, dynamic>> _contractors = [];
  String? _selectedContractorId;
  bool _isLoading = false;

  final List<String> _jobTypes = ['Full Time', 'Part Time', 'Seasonal'];
  final List<String> _workEnvironments = ['Indoor', 'Outdoor', 'Factory'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.job['title']);
    _descriptionController = TextEditingController(
      text: widget.job['description'],
    );
    _addressController = TextEditingController(text: widget.job['address']);
    _selectedJobType = widget.job['job_type'] ?? 'Full Time';
    _selectedWorkEnvironment = widget.job['work_environment'] ?? 'Indoor';
    _selectedContractorId = widget.job['contractor']?['id'];
    _fetchContractors();
  }

  Future<void> _fetchContractors() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/contractors/list/'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> contractorsData = json.decode(response.body);
        setState(() {
          _contractors = contractorsData
              .map(
                (contractor) => {
                  'id': contractor['id'].toString(),
                  'name': contractor['name'].toString(),
                },
              )
              .toList();
        });
      }
    } catch (e) {
      print('Error fetching contractors: $e');
    }
  }

  Future<void> _updateJob() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.put(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/jobs/user/${widget.job['id']}/edit/',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'title': _titleController.text,
          'description': _descriptionController.text,
          'address': _addressController.text,
          'job_type': _selectedJobType,
          'work_environment': _selectedWorkEnvironment,
          'contractor_id': _selectedContractorId,
          'user_id': widget.userId,
        }),
      );

      if (response.statusCode == 200) {
        Navigator.of(context).pop(json.decode(response.body));
      } else {
        final errorData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorData['error'] ?? 'Failed to update job'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating job: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600, maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Ionicons.create_outline, color: theme.primaryColor),
                  const SizedBox(width: 12),
                  Text(
                    'Edit Job',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Ionicons.close_outline),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Form fields
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Job Title',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) => value?.isEmpty == true
                            ? 'Please enter a job title'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        maxLines: 3,
                        validator: (value) => value?.isEmpty == true
                            ? 'Please enter a description'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          labelText: 'Address',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) => value?.isEmpty == true
                            ? 'Please enter an address'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedJobType,
                        decoration: InputDecoration(
                          labelText: 'Job Type',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: _jobTypes
                            .map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _selectedJobType = value!),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedWorkEnvironment,
                        decoration: InputDecoration(
                          labelText: 'Work Environment',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: _workEnvironments
                            .map(
                              (env) => DropdownMenuItem(
                                value: env,
                                child: Text(env),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _selectedWorkEnvironment = value!),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedContractorId,
                        decoration: InputDecoration(
                          labelText: 'Contractor',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: _contractors
                            .map(
                              (contractor) => DropdownMenuItem<String>(
                                value: contractor['id'],
                                child: Text(contractor['name']),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _selectedContractorId = value),
                        validator: (value) =>
                            value == null ? 'Please select a contractor' : null,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Cancel', style: GoogleFonts.outfit()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _updateJob,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              'Update Job',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
