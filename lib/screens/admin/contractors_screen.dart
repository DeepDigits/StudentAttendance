import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ionicons/ionicons.dart';
import 'dart:ui'; // Import for ImageFilter if using blur
import 'package:fluttertoast/fluttertoast.dart'; // Import fluttertoast
import 'package:http/http.dart' as http; // Import http
import 'dart:convert'; // Import jsonDecode
import 'package:intl/intl.dart'; // For date formatting
import 'package:flutter_spinkit/flutter_spinkit.dart'; // Import SpinKit

// Contractor model (similar to Worker)
class Contractor {
  final int id;
  final String name; // Contractors might have a company name or full name
  final String email;
  final String? phone;
  final String? address;
  final String? district;
  final String? city;
  final String? division;
  final String? pincode;
  final String? licenseNo;
  final String? profilePicUrl;
  final String? approvalStatus;
  final DateTime? createdAt;

  Contractor({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    this.district,
    this.city,
    this.division,
    this.pincode,
    this.licenseNo,
    this.profilePicUrl,
    this.approvalStatus,
    this.createdAt,
  });

  // Factory constructor to parse JSON from Django backend
  factory Contractor.fromJson(Map<String, dynamic> json) {
    return Contractor(
      id: json['id'] ?? 0,
      name: json['name'] ?? '', // Use 'name' field from backend
      email: json['email'] ?? '',
      phone: json['phone'],
      address: json['address'],
      district: json['district'],
      city: json['city'],
      division: json['division'],
      pincode: json['pincode'],
      licenseNo: json['license_no'],
      profilePicUrl: json['profile_pic_url'],
      approvalStatus: json['approval_status'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }
}

class ContractorsScreen extends StatefulWidget {
  const ContractorsScreen({super.key});

  @override
  State<ContractorsScreen> createState() => _ContractorsScreenState();
}

class _ContractorsScreenState extends State<ContractorsScreen> {
  late Future<List<Contractor>> _contractorRequestsFuture;
  Future<List<Contractor>> _approvedContractorsFuture = Future.value([]);
  final String _baseApiUrl =
      'https://workersapp.pythonanywhere.com/api'; // Base URL

  @override
  void initState() {
    super.initState();
    _contractorRequestsFuture = _fetchContractorRequests();
    _approvedContractorsFuture = _fetchApprovedContractors();
  }

  // --- Fetch Data ---
  Future<List<Contractor>> _fetchContractorRequests() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseApiUrl/contractorRequests/')); // New endpoint
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Contractor.fromJson(json)).toList();
      } else {
        throw Exception(
            'Failed to load contractor requests: Status code ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching contractor requests: $e');
      throw Exception(
          'Failed to load contractor requests. Check connection or API endpoint.');
    }
  }

  Future<List<Contractor>> _fetchApprovedContractors() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseApiUrl/contractors/approved/')); // New endpoint
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Contractor.fromJson(json)).toList();
      } else {
        throw Exception(
            'Failed to load approved contractors: Status code ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching approved contractors: $e');
      throw Exception(
          'Failed to load approved contractors. Check connection or API endpoint.');
    }
  }

  // --- Refresh Lists ---
  Future<void> _refreshContractorRequests() async {
    if (mounted) {
      setState(() {
        _contractorRequestsFuture = _fetchContractorRequests();
      });
    }
  }

  Future<void> _refreshApprovedContractors() async {
    if (mounted) {
      setState(() {
        _approvedContractorsFuture = _fetchApprovedContractors();
      });
    }
  }

  // --- API Calls for Actions ---
  Future<void> _acceptContractorRequest(int contractorId) async {
    final url = Uri.parse(
        '$_baseApiUrl/contractorRequests/$contractorId/accept/'); // New endpoint
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        Fluttertoast.showToast(
            msg: "Contractor approved successfully!",
            backgroundColor: Colors.green);
        _refreshContractorRequests(); // Refresh pending list
        _refreshApprovedContractors(); // Also refresh approved list
      } else {
        _handleApiError(response, 'Failed to accept contractor.');
      }
    } catch (e) {
      _handleConnectionError(e, 'accepting contractor');
    }
  }

  Future<void> _rejectContractorRequest(int contractorId, String reason) async {
    final url = Uri.parse(
        '$_baseApiUrl/contractorRequests/$contractorId/reject/'); // New endpoint
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'reason': reason}),
      );
      if (response.statusCode == 200) {
        Fluttertoast.showToast(
            msg: "Contractor rejected successfully!",
            backgroundColor: Colors.orange);
        _refreshContractorRequests(); // Refresh pending list
      } else {
        _handleApiError(response, 'Failed to reject contractor.');
      }
    } catch (e) {
      _handleConnectionError(e, 'rejecting contractor');
    }
  }

  Future<bool> _updateContractorApi(
      int contractorId, Map<String, dynamic> data) async {
    final url = Uri.parse(
        '$_baseApiUrl/contractors/$contractorId/update/'); // New endpoint
    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) {
        return true;
      } else {
        _handleApiError(response, 'Failed to update contractor');
        return false;
      }
    } catch (e) {
      _handleConnectionError(e, 'updating contractor');
      return false;
    }
  }

  Future<bool> _deleteContractorApi(int contractorId) async {
    final url = Uri.parse(
        '$_baseApiUrl/contractors/$contractorId/delete/'); // New endpoint
    try {
      final response = await http.delete(url);
      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        _handleApiError(response, 'Failed to delete contractor');
        return false;
      }
    } catch (e) {
      _handleConnectionError(e, 'deleting contractor');
      return false;
    }
  }

  // --- Error Handling Helpers ---
  void _handleApiError(http.Response response, String defaultMessage) {
    String errorMessage = defaultMessage;
    try {
      final responseBody = jsonDecode(response.body);
      errorMessage +=
          ' Error: ${responseBody['error'] ?? responseBody['message'] ?? 'Unknown API error'}';
    } catch (e) {
      // Ignore decoding error
    }
    Fluttertoast.showToast(
      msg: '$errorMessage (Status: ${response.statusCode})',
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
  }

  void _handleConnectionError(Object e, String action) {
    print('Error $action: $e');
    Fluttertoast.showToast(
      msg: "An error occurred while $action. Please check connection.",
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
  }

  // --- Dialogs and Bottom Sheets ---

  // Show Reject Reason Dialog (Similar to Worker)
  Future<String?> _showRejectReasonDialog(
      BuildContext bottomSheetContext, Contractor contractor) async {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color headerColor = Colors.orange.shade700; // Keep specific color
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

    return await showDialog<String?>(
      context: bottomSheetContext,
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
                  // Header - Keep specific color
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                    decoration: BoxDecoration(color: headerColor),
                    child: Row(
                      children: [
                        Icon(Ionicons.close_circle_outline,
                            color: headerForegroundColor, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text('Reject Contractor',
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: headerForegroundColor))),
                        IconButton(
                            icon: Icon(Ionicons.close_outline,
                                color: headerForegroundColor),
                            iconSize: 22,
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                            tooltip: 'Cancel',
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(null)),
                      ],
                    ),
                  ),
                  // Content - Use theme colors
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'Please provide a reason for rejecting ${contractor.name}:',
                              style: GoogleFonts.inter(
                                  fontSize: 14.0,
                                  color:
                                      contentTextColor, // Use theme text color
                                  height: 1.4)),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: reasonController,
                            autofocus: true,
                            maxLines: 3,
                            style: GoogleFonts.inter(
                                color: contentTextColor, // Use theme text color
                                fontSize: 14.0),
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
                                      width: 1.0)), // Use theme border color
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                      color: borderColor,
                                      width: 1.0)), // Use theme border color
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                      color: focusedBorderColor,
                                      width: 1.5)), // Use specific focus color
                              errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                      color: errorBorderColor,
                                      width: 1.0)), // Use theme error color
                              focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                      color: errorBorderColor,
                                      width: 1.5)), // Use theme error color
                            ),
                            validator: (value) =>
                                (value == null || value.trim().isEmpty)
                                    ? 'Reason cannot be empty'
                                    : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Actions - Use theme colors for cancel, keep specific for submit
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    child: Row(
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
                                    borderRadius: BorderRadius.circular(8))),
                            child: Text('Cancel',
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600, fontSize: 14)),
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(null)),
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
                                elevation: 2),
                            child: Text('Submit Reject',
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600, fontSize: 14)),
                            onPressed: () {
                              if (formKey.currentState!.validate())
                                Navigator.of(dialogContext)
                                    .pop(reasonController.text.trim());
                            }),
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
      // reasonController.dispose();
    });
  }

  // Show Review Bottom Sheet - updated to use theme colors
  void _showReviewBottomSheet(BuildContext context, Contractor contractor) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final initials =
        contractor.name.isNotEmpty ? contractor.name[0].toUpperCase() : '?';
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
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          expand: false,
          builder: (_, controller) {
            return Container(
              decoration: BoxDecoration(
                  color: sheetBackgroundColor, // Use theme background
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20)),
                  border: isDark // Add subtle border in dark mode
                      ? Border.all(
                          color: Colors.white.withOpacity(0.1), width: 0.5)
                      : null),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  // Content
                  ListView(
                    controller: controller,
                    padding: const EdgeInsets.only(top: 45),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Column(
                          children: [
                            const SizedBox(height: 30),
                            Text(contractor.name,
                                style: GoogleFonts.outfit(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        detailValueColor), // Use theme text color
                                textAlign: TextAlign.center),
                            const SizedBox(height: 4),
                            Text(contractor.email,
                                style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    color:
                                        subtleTextColor), // Use theme subtle color
                                textAlign: TextAlign.center),
                            const SizedBox(height: 20),
                            // Action Buttons - Keep specific colors
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                OutlinedButton(
                                  onPressed: () async {
                                    final String? reason =
                                        await _showRejectReasonDialog(
                                            bottomSheetContext, contractor);
                                    if (reason != null) {
                                      if (bottomSheetContext.mounted)
                                        Navigator.pop(bottomSheetContext);
                                      await Future.delayed(
                                          const Duration(milliseconds: 50));
                                      if (mounted)
                                        _rejectContractorRequest(
                                            contractor.id, reason);
                                    }
                                  },
                                  style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 30, vertical: 12),
                                      side: BorderSide(
                                          color: Colors.red.shade200),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10))),
                                  child: Text('Reject',
                                      style: GoogleFonts.outfit(
                                          color: Colors.red.shade700,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15)),
                                ),
                                const SizedBox(width: 16),
                                ElevatedButton(
                                  onPressed: () async {
                                    Navigator.pop(bottomSheetContext);
                                    await Future.delayed(
                                        const Duration(milliseconds: 50));
                                    if (mounted)
                                      _acceptContractorRequest(contractor.id);
                                  },
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green.shade600,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 30, vertical: 13),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                      elevation: 2),
                                  child: Text('Accept',
                                      style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Divider(
                                color: dividerColor), // Use theme divider color
                            const SizedBox(height: 16),
                            // Details Section
                            Align(
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                    padding: const EdgeInsets.only(
                                        left: 4.0, bottom: 8.0),
                                    child: Text('Details',
                                        style: GoogleFonts.outfit(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w600,
                                            color:
                                                detailValueColor)))), // Use theme text color
                            // Use updated _buildRequestDetailRow which uses theme colors
                            _buildRequestDetailRow(
                                Ionicons.call_outline,
                                'Phone',
                                contractor.phone ?? 'N/A',
                                detailLabelColor,
                                detailValueColor),
                            _buildRequestDetailRow(
                                Ionicons.home_outline,
                                'Address',
                                contractor.address ?? 'N/A',
                                detailLabelColor,
                                detailValueColor),
                            _buildRequestDetailRow(
                                Ionicons.location_outline,
                                'District',
                                contractor.district ?? 'N/A',
                                detailLabelColor,
                                detailValueColor),
                            _buildRequestDetailRow(
                                Ionicons.business_outline,
                                'City',
                                contractor.city ?? 'N/A',
                                detailLabelColor,
                                detailValueColor),
                            _buildRequestDetailRow(
                                Ionicons.map_outline,
                                'Division',
                                contractor.division ?? 'N/A',
                                detailLabelColor,
                                detailValueColor),
                            _buildRequestDetailRow(
                                Ionicons.barcode_outline,
                                'Pincode',
                                contractor.pincode ?? 'N/A',
                                detailLabelColor,
                                detailValueColor),
                            _buildRequestDetailRow(
                                Ionicons.shield_checkmark_outline,
                                'License No',
                                contractor.licenseNo ?? 'N/A',
                                detailLabelColor,
                                detailValueColor),
                            if (contractor.createdAt != null)
                              _buildRequestDetailRow(
                                  Ionicons.calendar_outline,
                                  'Requested On',
                                  DateFormat.yMMMd()
                                      .add_jm()
                                      .format(contractor.createdAt!),
                                  detailLabelColor,
                                  detailValueColor),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Avatar - Use theme colors
                  Positioned(
                    top: -35,
                    child: CircleAvatar(
                      radius: 45,
                      backgroundColor:
                          sheetBackgroundColor, // Match sheet background
                      child: CircleAvatar(
                        radius: 42,
                        backgroundColor:
                            avatarBackgroundColor, // Use theme primary color with opacity
                        child: contractor.profilePicUrl != null &&
                                contractor.profilePicUrl!.isNotEmpty
                            ? ClipOval(
                                child: Image.network(contractor.profilePicUrl!,
                                    fit: BoxFit.cover,
                                    width: 80,
                                    height: 80,
                                    loadingBuilder: (c, ch, lp) => lp == null
                                        ? ch
                                        : const Center(
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2.0)),
                                    errorBuilder: (c, e, st) => Text(initials,
                                        style: TextStyle(
                                            color:
                                                avatarTextColor, // Use theme primary color
                                            fontWeight: FontWeight.bold,
                                            fontSize: 24))))
                            : Text(initials,
                                style: TextStyle(
                                    color:
                                        avatarTextColor, // Use theme primary color
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24)),
                      ),
                    ),
                  ),
                  // Close Button - Use theme icon color
                  Positioned(
                      top: 10,
                      right: 10,
                      child: IconButton(
                          icon: Icon(Ionicons.close_circle,
                              color: theme.iconTheme.color
                                  ?.withOpacity(0.5)), // Use theme icon color
                          iconSize: 28,
                          onPressed: () => Navigator.pop(bottomSheetContext))),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // View Contractor Details Bottom Sheet - updated to use theme colors
  void _viewContractorDetails(Contractor contractor) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final initials =
        contractor.name.isNotEmpty ? contractor.name[0].toUpperCase() : '?';
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
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, controller) {
            return Container(
              decoration: BoxDecoration(
                  color: sheetBackgroundColor, // Use theme background
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20)),
                  border: isDark // Add subtle border in dark mode
                      ? Border.all(
                          color: Colors.white.withOpacity(0.1), width: 0.5)
                      : null),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  // Content
                  ListView(
                    controller: controller,
                    padding: const EdgeInsets.only(top: 45),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Column(
                          children: [
                            const SizedBox(height: 30),
                            Text(contractor.name,
                                style: GoogleFonts.outfit(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        detailValueColor), // Use theme text color
                                textAlign: TextAlign.center),
                            const SizedBox(height: 4),
                            Text(contractor.email,
                                style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    color:
                                        subtleTextColor), // Use theme subtle color
                                textAlign: TextAlign.center),
                            const SizedBox(height: 24),
                            Divider(
                                color: dividerColor), // Use theme divider color
                            const SizedBox(height: 16),
                            // Details Section
                            Align(
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                    padding: const EdgeInsets.only(
                                        left: 4.0, bottom: 8.0),
                                    child: Text('Details',
                                        style: GoogleFonts.outfit(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w600,
                                            color:
                                                detailValueColor)))), // Use theme text color
                            // Use updated _buildRequestDetailRow which uses theme colors
                            _buildRequestDetailRow(
                                Ionicons.id_card_outline,
                                'Contractor ID',
                                contractor.id.toString(),
                                detailLabelColor,
                                detailValueColor),
                            _buildRequestDetailRow(
                                Ionicons.mail_outline,
                                'Email',
                                contractor.email,
                                detailLabelColor,
                                detailValueColor),
                            _buildRequestDetailRow(
                                Ionicons.call_outline,
                                'Phone',
                                contractor.phone ?? 'N/A',
                                detailLabelColor,
                                detailValueColor),
                            _buildRequestDetailRow(
                                Ionicons.home_outline,
                                'Address',
                                contractor.address ?? 'N/A',
                                detailLabelColor,
                                detailValueColor),
                            _buildRequestDetailRow(
                                Ionicons.location_outline,
                                'District',
                                contractor.district ?? 'N/A',
                                detailLabelColor,
                                detailValueColor),
                            _buildRequestDetailRow(
                                Ionicons.business_outline,
                                'City',
                                contractor.city ?? 'N/A',
                                detailLabelColor,
                                detailValueColor),
                            _buildRequestDetailRow(
                                Ionicons.map_outline,
                                'Division',
                                contractor.division ?? 'N/A',
                                detailLabelColor,
                                detailValueColor),
                            _buildRequestDetailRow(
                                Ionicons.barcode_outline,
                                'Pincode',
                                contractor.pincode ?? 'N/A',
                                detailLabelColor,
                                detailValueColor),
                            _buildRequestDetailRow(
                                Ionicons.shield_checkmark_outline,
                                'License No',
                                contractor.licenseNo ?? 'N/A',
                                detailLabelColor,
                                detailValueColor),
                            if (contractor.createdAt != null)
                              _buildRequestDetailRow(
                                  Ionicons.calendar_outline,
                                  'Joined On',
                                  DateFormat.yMMMd()
                                      .format(contractor.createdAt!),
                                  detailLabelColor,
                                  detailValueColor),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Avatar - Use theme colors
                  Positioned(
                    top: -35,
                    child: CircleAvatar(
                      radius: 45,
                      backgroundColor:
                          sheetBackgroundColor, // Match sheet background
                      child: CircleAvatar(
                        radius: 42,
                        backgroundColor:
                            avatarBackgroundColor, // Use theme primary color with opacity
                        child: contractor.profilePicUrl != null &&
                                contractor.profilePicUrl!.isNotEmpty
                            ? ClipOval(
                                child: Image.network(contractor.profilePicUrl!,
                                    fit: BoxFit.cover,
                                    width: 80,
                                    height: 80,
                                    loadingBuilder: (c, ch, lp) => lp == null
                                        ? ch
                                        : const Center(
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2.0)),
                                    errorBuilder: (c, e, st) => Text(initials,
                                        style: TextStyle(
                                            color:
                                                avatarTextColor, // Use theme primary color
                                            fontWeight: FontWeight.bold,
                                            fontSize: 24))))
                            : Text(initials,
                                style: TextStyle(
                                    color:
                                        avatarTextColor, // Use theme primary color
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24)),
                      ),
                    ),
                  ),
                  // Close Button - Use theme icon color
                  Positioned(
                      top: 10,
                      right: 10,
                      child: IconButton(
                          icon: Icon(Ionicons.close_circle,
                              color: theme.iconTheme.color
                                  ?.withOpacity(0.5)), // Use theme icon color
                          iconSize: 28,
                          onPressed: () => Navigator.pop(bottomSheetContext))),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Edit Contractor Dialog - updated to use theme colors
  void _editContractor(Contractor contractor) {
    final nameController = TextEditingController(text: contractor.name);
    final emailController = TextEditingController(text: contractor.email);
    final phoneController = TextEditingController(text: contractor.phone);
    final addressController = TextEditingController(text: contractor.address);
    final districtController = TextEditingController(text: contractor.district);
    final cityController = TextEditingController(text: contractor.city);
    final divisionController = TextEditingController(text: contractor.division);
    final pincodeController = TextEditingController(text: contractor.pincode);
    final licenseController = TextEditingController(text: contractor.licenseNo);

    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color appBarColor =
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
                  // Header - Keep specific color
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                    decoration: BoxDecoration(color: appBarColor),
                    child: Row(
                      children: [
                        CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.white.withOpacity(0.8),
                            backgroundImage: contractor.profilePicUrl != null
                                ? NetworkImage(contractor.profilePicUrl!)
                                : null,
                            child: contractor.profilePicUrl == null
                                ? Icon(Ionicons.create_outline,
                                    color: appBarColor.computeLuminance() >
                                            0.5 // Adjust threshold if needed
                                        ? Colors.black54
                                        : Colors.white70,
                                    size: 18)
                                : null),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text('Edit Contractor',
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: headerForegroundColor))),
                        IconButton(
                            icon: Icon(Ionicons.close_outline,
                                color: headerForegroundColor),
                            iconSize: 22,
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                            tooltip: 'Cancel',
                            onPressed: () => Navigator.of(context).pop()),
                      ],
                    ),
                  ),
                  // Form - Use theme colors and helper
                  Flexible(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Use themed text field helper
                            _buildThemedTextField(
                                context,
                                nameController,
                                'Name',
                                Ionicons.business_outline,
                                contentTextColor,
                                iconColor),
                            const SizedBox(height: 12),
                            _buildThemedTextField(
                                context,
                                emailController,
                                'Email',
                                Ionicons.mail_outline,
                                contentTextColor,
                                iconColor),
                            const SizedBox(height: 12),
                            _buildThemedTextField(
                                context,
                                phoneController,
                                'Phone',
                                Ionicons.call_outline,
                                contentTextColor,
                                iconColor,
                                keyboardType: TextInputType.phone),
                            const SizedBox(height: 12),
                            Divider(
                                color: dividerColor,
                                height: 20), // Use theme divider color
                            _buildThemedTextField(
                                context,
                                addressController,
                                'Address',
                                Ionicons.home_outline,
                                contentTextColor,
                                iconColor,
                                maxLines: 2),
                            const SizedBox(height: 12),
                            _buildThemedTextField(
                                context,
                                districtController,
                                'District',
                                Ionicons.location_outline,
                                contentTextColor,
                                iconColor),
                            const SizedBox(height: 12),
                            _buildThemedTextField(
                                context,
                                cityController,
                                'City',
                                Ionicons.business_outline,
                                contentTextColor,
                                iconColor),
                            const SizedBox(height: 12),
                            _buildThemedTextField(
                                context,
                                divisionController,
                                'Division',
                                Ionicons.map_outline,
                                contentTextColor,
                                iconColor),
                            const SizedBox(height: 12),
                            _buildThemedTextField(
                                context,
                                pincodeController,
                                'Pincode',
                                Ionicons.barcode_outline,
                                contentTextColor,
                                iconColor,
                                keyboardType: TextInputType.number),
                            const SizedBox(height: 12),
                            _buildThemedTextField(
                                context,
                                licenseController,
                                'License No',
                                Ionicons.shield_checkmark_outline,
                                contentTextColor,
                                iconColor),
                            const SizedBox(height: 20),
                            // Actions - Use theme colors for cancel, keep specific for save
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
                                            borderRadius:
                                                BorderRadius.circular(8))),
                                    child: Text('Cancel',
                                        style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14)),
                                    onPressed: () =>
                                        Navigator.of(context).pop()),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          appBarColor, // Keep specific save button color
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 18, vertical: 10),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      elevation: 2),
                                  child: Text('Save Changes',
                                      style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14)),
                                  onPressed: () async {
                                    final updateData = {
                                      'name': nameController.text,
                                      'email': emailController.text,
                                      'phone': phoneController.text,
                                      'address': addressController.text,
                                      'district': districtController.text,
                                      'city': cityController.text,
                                      'division': divisionController.text,
                                      'pincode': pincodeController.text,
                                      'license_no': licenseController.text,
                                    };
                                    bool success = await _updateContractorApi(
                                        contractor.id, updateData);
                                    if (success && mounted) {
                                      _refreshApprovedContractors(); // Refresh list
                                      Navigator.of(context).pop();
                                      Fluttertoast.showToast(
                                          msg:
                                              "${nameController.text} updated successfully",
                                          backgroundColor:
                                              Colors.green.shade600);
                                    } else if (!success && mounted) {
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
      // Dispose controllers
      // ... (dispose controllers if needed) ...
    });
  }

  // Delete Contractor Dialog - updated to use theme colors
  void _deleteContractor(Contractor contractor) {
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
                  // Header - Keep specific color
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                    decoration: BoxDecoration(color: headerColor),
                    child: Row(
                      children: [
                        Icon(Ionicons.warning_outline,
                            color: headerForegroundColor, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text('Confirm Deletion',
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: headerForegroundColor))),
                        IconButton(
                            icon: Icon(Ionicons.close_outline,
                                color: headerForegroundColor),
                            iconSize: 22,
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                            tooltip: 'Cancel',
                            onPressed: () => Navigator.of(context).pop()),
                      ],
                    ),
                  ),
                  // Content - Use theme text color
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                    child: Text(
                        'Are you sure you want to delete ${contractor.name}? This action cannot be undone.',
                        style: GoogleFonts.inter(
                            fontSize: 14.5,
                            color: contentTextColor, // Use theme text color
                            height: 1.4),
                        textAlign: TextAlign.center),
                  ),
                  // Actions - Use theme colors for cancel, keep specific for delete
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    child: Row(
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
                                    borderRadius: BorderRadius.circular(8))),
                            child: Text('Cancel',
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600, fontSize: 14)),
                            onPressed: () => Navigator.of(context).pop()),
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
                              elevation: 2),
                          child: Text('Delete',
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600, fontSize: 14)),
                          onPressed: () async {
                            String contractorName = contractor.name;
                            bool success =
                                await _deleteContractorApi(contractor.id);
                            if (success && mounted) {
                              _refreshApprovedContractors(); // Refresh list
                              Navigator.of(context).pop();
                              Fluttertoast.showToast(
                                  msg: "$contractorName deleted successfully",
                                  backgroundColor: Colors.red.shade600);
                            } else if (!success && mounted) {
                              Fluttertoast.showToast(
                                  msg: "Deletion failed. Please try again.",
                                  backgroundColor: Colors.red);
                              Navigator.of(context).pop();
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

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    // Use theme colors instead of hardcoded colors
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    // Get colors from theme, adjusting for dark mode based on screenshot
    // Use AppBar theme color for TabBar background
    final Color tabBarBackgroundColor =
        theme.appBarTheme.backgroundColor ?? theme.primaryColor;
    final Color tabBarForegroundColor =
        theme.appBarTheme.foregroundColor ?? theme.colorScheme.onPrimary;
    final Color indicatorColor =
        theme.indicatorColor; // Use theme's indicator color

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Container(
                color: tabBarBackgroundColor, // Use AppBar theme color
                child: TabBar(
                  labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  unselectedLabelStyle: GoogleFonts.inter(),
                  labelColor:
                      tabBarForegroundColor, // Use AppBar theme foreground color
                  unselectedLabelColor: tabBarForegroundColor.withOpacity(
                      0.7), // Adjust opacity based on AppBar foreground
                  indicatorColor: indicatorColor, // Use theme indicator color
                  tabs: const [
                    Tab(text: 'Contractor Details'),
                    Tab(text: 'Contractor Requests'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildApprovedContractorsList(),
                    _buildContractorRequestsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Tab Builders ---
  Widget _buildApprovedContractorsList() {
    final theme = Theme.of(context); // Get theme
    return RefreshIndicator(
      onRefresh: _refreshApprovedContractors,
      child: FutureBuilder<List<Contractor>>(
        future: _approvedContractorsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: SpinKitFadingCircle(
                    color: theme.primaryColor, size: 50.0)); // Use theme color
          } else if (snapshot.hasError) {
            return _buildErrorWidget(
                snapshot.error, _refreshApprovedContractors, "contractors");
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyWidget(
                _refreshApprovedContractors, "contractors");
          }
          final approvedContractors = snapshot.data!;
          return ListView.builder(
            padding:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
            itemCount: approvedContractors.length,
            itemBuilder: (context, index) =>
                _buildContractorCard(approvedContractors[index]),
          );
        },
      ),
    );
  }

  Widget _buildContractorRequestsTab() {
    final theme = Theme.of(context); // Get theme
    return RefreshIndicator(
      onRefresh: _refreshContractorRequests,
      child: FutureBuilder<List<Contractor>>(
        future: _contractorRequestsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: SpinKitFadingCircle(
                    color: theme.primaryColor, size: 50.0)); // Use theme color
          } else if (snapshot.hasError) {
            return _buildErrorWidget(
                snapshot.error, _refreshContractorRequests, "requests");
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyWidget(_refreshContractorRequests, "requests");
          }
          final requests = snapshot.data!;
          return ListView.builder(
            padding:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
            itemCount: requests.length,
            itemBuilder: (context, index) =>
                _buildContractorRequestCard(requests[index]),
          );
        },
      ),
    );
  }

  // --- Card Builders ---
  Widget _buildContractorCard(Contractor contractor) {
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
              color: isDark
                  ? Colors.black.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.1), // Adjust shadow for theme
              blurRadius: 8,
              spreadRadius: 1,
              offset: const Offset(0, 2))
        ],
        border: Border.all(
          // Add subtle border based on theme
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.grey.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _viewContractorDetails(contractor),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: isDark
                      ? theme.primaryColor.withOpacity(0.2)
                      : Colors.grey.shade100, // Adjust background for theme
                  backgroundImage: contractor.profilePicUrl != null
                      ? NetworkImage(contractor.profilePicUrl!)
                      : null,
                  child: contractor.profilePicUrl == null
                      ? Icon(Ionicons.business_outline,
                          color: isDark
                              ? Colors.white.withOpacity(0.6)
                              : Colors
                                  .grey.shade400, // Adjust icon color for theme
                          size: 32)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(contractor.name,
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 16.5,
                              color: theme.textTheme.bodyLarge
                                  ?.color), // Use theme text color
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Row(children: [
                        Icon(Ionicons.mail_outline,
                            size: 15,
                            color: cardIconColor), // Use defined icon color
                        const SizedBox(width: 6),
                        Expanded(
                            child: Text(contractor.email,
                                style: GoogleFonts.inter(
                                    fontSize: 13.5,
                                    color:
                                        cardDetailTextColor), // Use defined detail text color
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1))
                      ]),
                      const SizedBox(height: 4),
                      Row(children: [
                        Icon(Ionicons.call_outline,
                            size: 15,
                            color: cardIconColor), // Use defined icon color
                        const SizedBox(width: 6),
                        Expanded(
                            child: Text(contractor.phone ?? 'N/A',
                                style: GoogleFonts.inter(
                                    fontSize: 13.5,
                                    color:
                                        cardDetailTextColor), // Use defined detail text color
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1))
                      ]),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: Icon(Ionicons.ellipsis_vertical,
                      color: popupMenuIconColor), // Use defined icon color
                  tooltip: "Actions",
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  offset: Offset(0, 40),
                  color: theme.popupMenuTheme.color ??
                      theme.cardColor, // Use theme popup menu color
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    _buildPopupMenuItem(
                        context: context,
                        value: 'view',
                        icon: Ionicons.eye_outline,
                        text: 'View Details'),
                    _buildPopupMenuItem(
                        context: context,
                        value: 'edit',
                        icon: Ionicons.create_outline,
                        text: 'Edit Contractor'),
                    const PopupMenuDivider(),
                    _buildPopupMenuItem(
                        context: context,
                        value: 'delete',
                        icon: Ionicons.trash_outline,
                        text: 'Delete Contractor',
                        color: Colors.red[700]), // Keep specific delete color
                  ],
                  onSelected: (String result) {
                    switch (result) {
                      case 'view':
                        _viewContractorDetails(contractor);
                        break;
                      case 'edit':
                        _editContractor(contractor);
                        break;
                      case 'delete':
                        _deleteContractor(contractor);
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

  Widget _buildContractorRequestCard(Contractor contractor) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final initials =
        contractor.name.isNotEmpty ? contractor.name[0].toUpperCase() : '?';
    final avatarBackgroundColor = theme.primaryColor.withOpacity(0.1);
    final avatarTextColor = theme.primaryColor;
    final Color subtleTextColor = theme.textTheme.bodySmall?.color ??
        (isDark ? Colors.grey.shade400 : Colors.grey.shade600);

    return Card(
      color: theme.cardColor, // Use theme card color
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 1.0,
      shadowColor: isDark
          ? Colors.black.withOpacity(0.2)
          : Colors.grey.withOpacity(0.1), // Adjust shadow for theme
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: avatarBackgroundColor, // Use theme color
              child: contractor.profilePicUrl != null &&
                      contractor.profilePicUrl!.isNotEmpty
                  ? ClipOval(
                      child: Image.network(contractor.profilePicUrl!,
                          fit: BoxFit.cover,
                          width: 48,
                          height: 48,
                          loadingBuilder: (c, ch, lp) => lp == null
                              ? ch
                              : Center(
                                  child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      value: lp.expectedTotalBytes != null
                                          ? lp.cumulativeBytesLoaded /
                                              lp.expectedTotalBytes!
                                          : null)),
                          errorBuilder: (c, e, st) => Text(initials,
                              style: TextStyle(
                                  color: avatarTextColor, // Use theme color
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16))))
                  : Text(initials,
                      style: TextStyle(
                          color: avatarTextColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)), // Use theme color
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(contractor.name,
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: theme.textTheme.bodyLarge
                              ?.color), // Use theme text color
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(contractor.email,
                      style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: subtleTextColor), // Use theme subtle color
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton(
                  onPressed: () => _showReviewBottomSheet(context, contractor),
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      side: BorderSide(
                          color: theme.dividerColor), // Use theme divider color
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8))),
                  child: Text('Review',
                      style: GoogleFonts.inter(
                          color: isDark
                              ? Colors.white70
                              : Colors
                                  .grey.shade700, // Adjust text color for theme
                          fontWeight: FontWeight.w500,
                          fontSize: 13)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _acceptContractorRequest(contractor.id),
                  style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.green.shade600, // Keep specific accept color
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 9),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      elevation: 1.5),
                  child: Text('Accept',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets ---
  Widget _buildErrorWidget(Object? error, VoidCallback onRetry, String type) {
    final theme = Theme.of(context); // Get theme
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Ionicons.cloud_offline_outline,
                size: 60,
                color: theme.textTheme.bodySmall?.color
                    ?.withOpacity(0.6)), // Use theme color
            const SizedBox(height: 16),
            Text('Error loading $type',
                style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: theme
                        .textTheme.bodyLarge?.color), // Use theme text color
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('$error',
                style: GoogleFonts.inter(
                    fontSize: 13,
                    color: theme
                        .textTheme.bodySmall?.color), // Use theme text color
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
                icon: const Icon(Ionicons.refresh_outline, size: 18),
                label: const Text('Retry'),
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor, // Use theme color
                    foregroundColor:
                        theme.colorScheme.onPrimary)), // Use theme color
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget(VoidCallback onRefresh, String type) {
    final theme = Theme.of(context); // Get theme
    final bool isDark = theme.brightness == Brightness.dark; // Check dark mode

    String message = type == "requests"
        ? 'No pending contractor requests found.'
        : 'No approved contractors found.';
    IconData icon = type == "requests"
        ? Ionicons.documents_outline
        : Ionicons.business_outline;

    // Define button colors based on theme
    final Color buttonBackgroundColor = isDark
        ? Colors.grey.shade700 // Lighter grey for dark mode button background
        : theme.primaryColor; // Primary color for light mode
    final Color buttonForegroundColor = isDark
        ? Colors.white // White text for dark mode button
        : theme.colorScheme.onPrimary; // onPrimary for light mode

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon,
              size: 60,
              color: theme.textTheme.bodySmall?.color
                  ?.withOpacity(0.6)), // Use theme color
          const SizedBox(height: 16),
          Text(message,
              style: GoogleFonts.inter(
                  fontSize: 16,
                  color: theme
                      .textTheme.bodySmall?.color)), // Use theme text color
          const SizedBox(height: 20),
          ElevatedButton.icon(
              icon: const Icon(Ionicons.refresh_outline, size: 18),
              label: const Text('Refresh'),
              onPressed: onRefresh,
              style: ElevatedButton.styleFrom(
                  backgroundColor:
                      buttonBackgroundColor, // Use adjusted background color
                  foregroundColor:
                      buttonForegroundColor)), // Use adjusted foreground color
        ],
      ),
    );
  }

  // Reusable TextField builder - updated to use theme colors
  Widget _buildThemedTextField(
      BuildContext context,
      TextEditingController controller,
      String label,
      IconData? icon,
      Color textColor,
      Color iconColor,
      {int maxLines = 1,
      TextInputType? keyboardType}) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final Color fillColor = isDark
        ? Colors.grey.shade800.withOpacity(0.5)
        : Colors.grey.shade100.withOpacity(0.5);
    final Color fieldTextColor = theme.textTheme.bodyLarge?.color ?? textColor;
    final Color fieldIconColor =
        theme.iconTheme.color?.withOpacity(0.7) ?? iconColor;
    final Color labelColor =
        theme.textTheme.bodySmall?.color ?? Colors.grey.shade600;
    final Color borderColor =
        isDark ? Colors.grey.shade600 : Colors.grey.shade300;
    final Color focusedBorderColor = theme.primaryColor;

    return TextField(
      controller: controller,
      style: GoogleFonts.inter(color: fieldTextColor, fontSize: 14.5),
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: labelColor, fontSize: 13),
        prefixIcon:
            icon != null ? Icon(icon, color: fieldIconColor, size: 20) : null,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14.0, horizontal: 12.0),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: borderColor, width: 1.0)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: borderColor, width: 1.0)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: focusedBorderColor, width: 1.5)),
      ),
    );
  }

  // Reusable Detail Row builder - updated to use theme colors
  Widget _buildRequestDetailRow(IconData icon, String label, String value,
      Color iconColor, Color valueColor) {
    final theme = Theme.of(context);
    final Color themeIconColor =
        theme.textTheme.bodySmall?.color?.withOpacity(0.8) ?? iconColor;
    final Color themeValueColor =
        theme.textTheme.bodyLarge?.color ?? valueColor;
    final Color themeLabelColor = theme.textTheme.bodySmall?.color ?? iconColor;

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 4.0),
      leading: Icon(icon, size: 20, color: themeIconColor),
      title: Text(label,
          style: GoogleFonts.outfit(
              fontSize: 12.5,
              color: themeLabelColor,
              fontWeight: FontWeight.w500)),
      subtitle: Padding(
          padding: const EdgeInsets.only(top: 2.0),
          child: Text(value,
              style: GoogleFonts.outfit(
                  fontSize: 14.5,
                  color: themeValueColor,
                  fontWeight: FontWeight.w500,
                  height: 1.3))),
    );
  }

  // Reusable PopupMenuItem builder - updated to use theme colors
  PopupMenuItem<String> _buildPopupMenuItem(
      {required BuildContext context,
      required String value,
      required IconData icon,
      required String text,
      Color? color}) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    // Use provided color if available, otherwise use theme's default text color for popups,
    // ensuring a fallback for dark/light mode.
    final itemColor = color ??
        theme.popupMenuTheme.textStyle?.color ??
        (isDark ? Colors.grey.shade200 : Colors.grey.shade800);

    return PopupMenuItem<String>(
      value: value,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(children: [
        Icon(icon, size: 20, color: itemColor), // Use determined item color
        const SizedBox(width: 12),
        Text(text,
            style: GoogleFonts.inter(
                fontSize: 14,
                color: itemColor,
                fontWeight: FontWeight.w500)) // Use determined item color
      ]),
    );
  }
}
