import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ionicons/ionicons.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:attendance_tracking/config/api_config.dart';

class HelpCentersScreen extends StatefulWidget {
  const HelpCentersScreen({Key? key}) : super(key: key);

  @override
  State<HelpCentersScreen> createState() => _HelpCentersScreenState();
}

class _HelpCentersScreenState extends State<HelpCentersScreen> {
  List<Map<String, dynamic>> _helpCentersByDivision = [];
  List<Map<String, dynamic>> _filteredHelpCentersByDivision = [];
  List<Map<String, dynamic>> _divisions = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  // Controllers for dialogs
  final _divisionNameController = TextEditingController();
  final _divisionDescriptionController = TextEditingController();
  final _helpCenterNameController = TextEditingController();
  final _helpCenterAddressController = TextEditingController();
  // Separate address field controllers
  final _helpCenterStreetController = TextEditingController();
  final _helpCenterCityController = TextEditingController();
  final _helpCenterStateController = TextEditingController();
  final _helpCenterPinCodeController = TextEditingController();
  final _helpCenterContactController = TextEditingController();
  final _helpCenterEmailController = TextEditingController();
  final _helpCenterDescriptionController = TextEditingController();
  final _helpCenterHoursController = TextEditingController();
  final _searchController = TextEditingController();

  int? _selectedDivisionId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _divisionNameController.dispose();
    _divisionDescriptionController.dispose();
    _helpCenterNameController.dispose();
    _helpCenterAddressController.dispose();
    _helpCenterStreetController.dispose();
    _helpCenterCityController.dispose();
    _helpCenterStateController.dispose();
    _helpCenterPinCodeController.dispose();
    _helpCenterContactController.dispose();
    _helpCenterEmailController.dispose();
    _helpCenterDescriptionController.dispose();
    _helpCenterHoursController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await Future.wait([_fetchHelpCenters(), _fetchDivisions()]);
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchHelpCenters() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/help-centers/'),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _helpCentersByDivision = data.cast<Map<String, dynamic>>();
          _filteredHelpCentersByDivision = _helpCentersByDivision;
        });
      } else {
        throw Exception('Failed to load help centers: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching help centers: $e');
    }
  }

  Future<void> _fetchDivisions() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/divisions/'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _divisions = data.cast<Map<String, dynamic>>();
        });
      } else {
        throw Exception('Failed to load divisions: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching divisions: $e');
    }
  }

  void _filterHelpCenters(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredHelpCentersByDivision = _helpCentersByDivision;
      } else {
        _filteredHelpCentersByDivision = _helpCentersByDivision
            .map((division) {
              final helpCenters = division['help_centers'] as List<dynamic>;
              final filteredHelpCenters = helpCenters.where((helpCenter) {
                final name = helpCenter['name']?.toString().toLowerCase() ?? '';
                final address =
                    helpCenter['address']?.toString().toLowerCase() ?? '';
                final description =
                    helpCenter['description']?.toString().toLowerCase() ?? '';
                final queryLower = query.toLowerCase();

                return name.contains(queryLower) ||
                    address.contains(queryLower) ||
                    description.contains(queryLower);
              }).toList();

              return {...division, 'help_centers': filteredHelpCenters};
            })
            .where((division) {
              final divisionName =
                  division['division_name']?.toString().toLowerCase() ?? '';
              final queryLower = query.toLowerCase();
              final helpCenters = division['help_centers'] as List<dynamic>;

              // Include division if division name matches OR if it has any matching help centers
              // This ensures divisions with no help centers are still shown if their name matches
              return divisionName.contains(queryLower) ||
                  helpCenters.isNotEmpty;
            })
            .toList();
      }
    });
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not launch phone dialer for $phoneNumber'),
        ),
      );
    }
  }

  Future<void> _createDivision() async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/divisions/create/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'name': _divisionNameController.text.trim(),
          'description': _divisionDescriptionController.text.trim(),
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Division created successfully')),
        );
        _clearDivisionForm();
        Navigator.of(context).pop();
        await _loadData();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to create division');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _updateDivision(int divisionId) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/divisions/$divisionId/update/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'name': _divisionNameController.text.trim(),
          'description': _divisionDescriptionController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Division updated successfully')),
        );
        _clearDivisionForm();
        Navigator.of(context).pop();
        await _loadData();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to update division');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _deleteDivision(int divisionId, String divisionName) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/divisions/$divisionId/delete/'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Division deleted successfully')),
        );
        await _loadData();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to delete division');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _createHelpCenter() async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/help-centers/create/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'name': _helpCenterNameController.text.trim(),
          'division_id': _selectedDivisionId,
          'address': _combineAddressFields(),
          'contact_number': _helpCenterContactController.text.trim(),
          'email': _helpCenterEmailController.text.trim(),
          'description': _helpCenterDescriptionController.text.trim(),
          'operating_hours': _helpCenterHoursController.text.trim(),
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Help center created successfully')),
        );
        _clearHelpCenterForm();
        Navigator.of(context).pop();
        await _loadData();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to create help center');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _updateHelpCenter(int helpCenterId) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/help-centers/$helpCenterId/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'name': _helpCenterNameController.text.trim(),
          'division_id': _selectedDivisionId,
          'address': _combineAddressFields(),
          'contact_number': _helpCenterContactController.text.trim(),
          'email': _helpCenterEmailController.text.trim(),
          'description': _helpCenterDescriptionController.text.trim(),
          'operating_hours': _helpCenterHoursController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Help center updated successfully')),
        );
        _clearHelpCenterForm();
        Navigator.of(context).pop();
        await _loadData();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to update help center');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _deleteHelpCenter(int helpCenterId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/help-centers/$helpCenterId/'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Help center deleted successfully')),
        );
        await _loadData();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to delete help center');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // Helper method to combine separate address fields into a single address string
  String _combineAddressFields() {
    final street = _helpCenterStreetController.text.trim();
    final city = _helpCenterCityController.text.trim();
    final state = _helpCenterStateController.text.trim();
    final pinCode = _helpCenterPinCodeController.text.trim();

    List<String> addressParts = [];
    if (street.isNotEmpty) addressParts.add(street);
    if (city.isNotEmpty) addressParts.add(city);
    if (state.isNotEmpty) addressParts.add(state);
    if (pinCode.isNotEmpty) addressParts.add(pinCode);

    return addressParts.join(', ');
  }

  // Helper method to parse a combined address back into separate fields
  void _parseAddressFields(String address) {
    _helpCenterStreetController.clear();
    _helpCenterCityController.clear();
    _helpCenterStateController.clear();
    _helpCenterPinCodeController.clear();

    if (address.isNotEmpty) {
      List<String> parts = address.split(', ');
      if (parts.isNotEmpty) _helpCenterStreetController.text = parts[0];
      if (parts.length > 1) _helpCenterCityController.text = parts[1];
      if (parts.length > 2) _helpCenterStateController.text = parts[2];
      if (parts.length > 3) _helpCenterPinCodeController.text = parts[3];
    }
  }

  void _clearDivisionForm() {
    _divisionNameController.clear();
    _divisionDescriptionController.clear();
  }

  void _clearHelpCenterForm() {
    _helpCenterNameController.clear();
    _helpCenterAddressController.clear();
    _helpCenterStreetController.clear();
    _helpCenterCityController.clear();
    _helpCenterStateController.clear();
    _helpCenterPinCodeController.clear();
    _helpCenterContactController.clear();
    _helpCenterEmailController.clear();
    _helpCenterDescriptionController.clear();
    _helpCenterHoursController.clear();
    _selectedDivisionId = null;
  }

  void _showCreateDivisionDialog() {
    _clearDivisionForm();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Create New Division'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _divisionNameController,
                decoration: const InputDecoration(
                  labelText: 'Division Name *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _divisionDescriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _createDivision,
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showCreateHelpCenterDialog() {
    _clearHelpCenterForm();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Create New Help Center'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _helpCenterNameController,
                decoration: const InputDecoration(
                  labelText: 'Help Center Name *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedDivisionId,
                decoration: const InputDecoration(
                  labelText: 'Division *',
                  border: OutlineInputBorder(),
                ),
                items: _divisions.map((division) {
                  return DropdownMenuItem<int>(
                    value: division['id'],
                    child: Text(division['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDivisionId = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              // Street Address
              TextField(
                controller: _helpCenterStreetController,
                decoration: InputDecoration(
                  labelText: 'Street Address *',
                  prefixIcon: Icon(
                    Ionicons.home_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              // City
              TextField(
                controller: _helpCenterCityController,
                decoration: InputDecoration(
                  labelText: 'City *',
                  prefixIcon: Icon(
                    Ionicons.location_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              // State
              TextField(
                controller: _helpCenterStateController,
                decoration: InputDecoration(
                  labelText: 'State *',
                  prefixIcon: Icon(
                    Ionicons.map_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              // PIN Code
              TextField(
                controller: _helpCenterPinCodeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'PIN Code *',
                  prefixIcon: Icon(
                    Ionicons.pin_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _helpCenterContactController,
                decoration: const InputDecoration(
                  labelText: 'Contact Number *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _helpCenterEmailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _helpCenterDescriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _helpCenterHoursController,
                decoration: const InputDecoration(
                  labelText: 'Operating Hours',
                  hintText: 'e.g., 9:00 AM - 5:00 PM',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _createHelpCenter,
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEditHelpCenterDialog(Map<String, dynamic> helpCenter) {
    // Pre-fill the form with existing data
    _helpCenterNameController.text = helpCenter['name'] ?? '';
    _helpCenterAddressController.text = helpCenter['address'] ?? '';
    // Parse the combined address into separate fields
    _parseAddressFields(helpCenter['address'] ?? '');
    _helpCenterContactController.text = helpCenter['contact_number'] ?? '';
    _helpCenterEmailController.text = helpCenter['email'] ?? '';
    _helpCenterDescriptionController.text = helpCenter['description'] ?? '';
    _helpCenterHoursController.text = helpCenter['operating_hours'] ?? '';
    _selectedDivisionId = helpCenter['division_id'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              Ionicons.create_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text('Edit Help Center'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _helpCenterNameController,
                decoration: const InputDecoration(
                  labelText: 'Help Center Name *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedDivisionId,
                decoration: const InputDecoration(
                  labelText: 'Division *',
                  border: OutlineInputBorder(),
                ),
                items: _divisions.map((division) {
                  return DropdownMenuItem<int>(
                    value: division['id'],
                    child: Text(division['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDivisionId = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _helpCenterAddressController,
                decoration: const InputDecoration(
                  labelText: 'Address *',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _helpCenterContactController,
                decoration: const InputDecoration(
                  labelText: 'Contact Number *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _helpCenterEmailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _helpCenterDescriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _helpCenterHoursController,
                decoration: const InputDecoration(
                  labelText: 'Operating Hours',
                  hintText: 'e.g., 9:00 AM - 5:00 PM',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _clearHelpCenterForm();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _updateHelpCenter(helpCenter['id']),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(Map<String, dynamic> helpCenter) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              Ionicons.warning_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 8),
            const Text('Delete Help Center'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete this help center?',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    helpCenter['name'],
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    helpCenter['address'],
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This action cannot be undone.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteHelpCenter(helpCenter['id']);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showEditDivisionDialog(Map<String, dynamic> division) {
    // Pre-fill the form with existing division data
    _divisionNameController.text = division['division_name'] ?? '';
    _divisionDescriptionController.text =
        division['division_description'] ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Division'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _divisionNameController,
                decoration: const InputDecoration(
                  labelText: 'Division Name *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _divisionDescriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _updateDivision(division['division_id']),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDivisionConfirmDialog(Map<String, dynamic> division) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Division'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 60),
            const SizedBox(height: 16),
            Text(
              'Are you sure you want to delete "${division['division_name']}"?',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'This action cannot be undone. All associated help centers must be moved or deleted first.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteDivision(
                division['division_id'],
                division['division_name'],
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading help centers',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(_error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Search Bar
                Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterHelpCenters,
                    decoration: InputDecoration(
                      hintText:
                          'Search help centers, divisions, or addresses...',
                      hintStyle: GoogleFonts.roboto(
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(
                          0.6,
                        ),
                      ),
                      prefixIcon: Icon(
                        Ionicons.search_outline,
                        color: theme.colorScheme.primary,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Ionicons.close_outline,
                                color: theme.textTheme.bodyMedium?.color
                                    ?.withOpacity(0.6),
                              ),
                              onPressed: () {
                                _searchController.clear();
                                _filterHelpCenters('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
                // Content
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadData,
                    child: _filteredHelpCentersByDivision.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _searchQuery.isNotEmpty
                                      ? Ionicons.search_outline
                                      : Ionicons.business_outline,
                                  size: 64,
                                  color: theme.disabledColor,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isNotEmpty
                                      ? 'No Results Found'
                                      : 'No Help Centers Found',
                                  style: theme.textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _searchQuery.isNotEmpty
                                      ? 'Try adjusting your search terms'
                                      : 'Create your first help center to get started',
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(
                              left: 16,
                              right: 16,
                              bottom: 100, // Extra space for FABs
                            ),
                            itemCount: _filteredHelpCentersByDivision.length,
                            itemBuilder: (context, index) {
                              final divisionData =
                                  _filteredHelpCentersByDivision[index];
                              return _buildDivisionCard(divisionData);
                            },
                          ),
                  ),
                ),
              ],
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _showCreateDivisionDialog,
            heroTag: "division",
            tooltip: 'Add Division',
            child: const Icon(Ionicons.location_outline),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _showCreateHelpCenterDialog,
            heroTag: "help_center",
            tooltip: 'Add Help Center',
            child: const Icon(Ionicons.business_outline),
          ),
        ],
      ),
    );
  }

  Widget _buildDivisionCard(Map<String, dynamic> divisionData) {
    final theme = Theme.of(context);
    final helpCenters = divisionData['help_centers'] as List<dynamic>;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          childrenPadding: const EdgeInsets.only(bottom: 12),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withOpacity(0.8),
                  theme.colorScheme.primary,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Ionicons.location, color: Colors.white, size: 24),
          ),
          title: Text(
            divisionData['division_name'],
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              if (divisionData['division_description'] != null)
                Text(
                  divisionData['division_description'],
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${helpCenters.length} Help Center${helpCenters.length != 1 ? 's' : ''}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  Ionicons.create_outline,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                onPressed: () => _showEditDivisionDialog(divisionData),
                tooltip: 'Edit Division',
              ),
              IconButton(
                icon: Icon(
                  Ionicons.trash_outline,
                  color: theme.colorScheme.error,
                  size: 20,
                ),
                onPressed: () => _showDeleteDivisionConfirmDialog(divisionData),
                tooltip: 'Delete Division',
              ),
            ],
          ),
          children: helpCenters.map((helpCenter) {
            return _buildHelpCenterTile(helpCenter);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildHelpCenterTile(Map<String, dynamic> helpCenter) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and actions
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.secondary.withOpacity(0.8),
                        theme.colorScheme.secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Ionicons.business, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    helpCenter['name'],
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.titleLarge?.color,
                    ),
                  ),
                ),
                // Action buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _showEditHelpCenterDialog(helpCenter),
                      icon: Icon(
                        Ionicons.create_outline,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      onPressed: () => _showDeleteConfirmDialog(helpCenter),
                      icon: Icon(
                        Ionicons.trash_outline,
                        color: theme.colorScheme.error,
                        size: 20,
                      ),
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Address
            _buildInfoRow(
              icon: Ionicons.location_outline,
              text: helpCenter['address'],
              theme: theme,
            ),
            const SizedBox(height: 8),

            // Contact number
            _buildInfoRow(
              icon: Ionicons.call_outline,
              text: helpCenter['contact_number'],
              theme: theme,
            ),

            // Operating hours
            if (helpCenter['operating_hours'] != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                icon: Ionicons.time_outline,
                text: helpCenter['operating_hours'],
                theme: theme,
              ),
            ],

            // Email
            if (helpCenter['email'] != null &&
                helpCenter['email'].isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                icon: Ionicons.mail_outline,
                text: helpCenter['email'],
                theme: theme,
              ),
            ],

            const SizedBox(height: 12),

            // Description
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                helpCenter['description'],
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  color: theme.textTheme.bodyMedium?.color,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: 16),

            // Call button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _makePhoneCall(helpCenter['contact_number']),
                icon: const Icon(Ionicons.call, size: 18),
                label: Text(
                  'Call Now',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String text,
    required ThemeData theme,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.roboto(
              fontSize: 14,
              color: theme.textTheme.bodyMedium?.color,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
