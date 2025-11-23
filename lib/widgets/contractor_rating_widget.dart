import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ionicons/ionicons.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';

class ContractorRatingWidget extends StatelessWidget {
  final String jobId;
  final String contractorId;
  final String workerId;
  final Function() onRateRequested;
  final Color textColor;
  final Color subtleTextColor;

  const ContractorRatingWidget({
    Key? key,
    required this.jobId,
    required this.contractorId,
    required this.workerId,
    required this.onRateRequested,
    required this.textColor,
    required this.subtleTextColor,
  }) : super(key: key);

  Future<Map<String, dynamic>?> _getContractorRating() async {
    try {
      print('🔍 Checking for existing rating...');
      print(
          'Job ID: $jobId, Contractor ID: $contractorId, Worker ID: $workerId');

      // First, try the dedicated check endpoint
      final checkUrl =
          '${ApiConfig.baseUrl}/api/contractor-feedback/check/$contractorId/$jobId/$workerId/';
      print('Trying check endpoint: $checkUrl');

      final checkResponse = await http.get(
        Uri.parse(checkUrl),
        headers: {'Accept': 'application/json'},
      );

      print('Check response status: ${checkResponse.statusCode}');
      print('Check response body: ${checkResponse.body}');

      if (checkResponse.statusCode == 200) {
        final checkData = json.decode(checkResponse.body);
        if (checkData['exists'] == true && checkData['rating_data'] != null) {
          print(
              '🎯 FOUND RATING via check endpoint: ${checkData['rating_data']}');
          return checkData['rating_data'];
        }
      }

      print('❌ No existing rating found');
      return null;
    } catch (e) {
      print('❌ Error checking for existing rating: $e');
      return null;
    }
  }

  Widget _buildExistingRating(Map<String, dynamic> ratingData) {
    final int rating = ratingData['rating'] != null
        ? int.tryParse(ratingData['rating'].toString()) ?? 0
        : 0;

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Ionicons.checkmark_circle,
                color: Colors.green,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'You already rated this contractor for this job',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (int i = 1; i <= 5; i++)
                Icon(
                  i <= rating ? Ionicons.star : Ionicons.star_outline,
                  color: i <= rating ? Colors.amber : Colors.grey,
                  size: 16,
                ),
              const SizedBox(width: 8),
              Text(
                '$rating/5',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[800],
                ),
              ),
            ],
          ),
          if (ratingData['feedback_text'] != null &&
              ratingData['feedback_text'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '"${ratingData['feedback_text']}"',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: subtleTextColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRateButton() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onRateRequested,
            icon: const Icon(
              Ionicons.star_outline,
              size: 18,
            ),
            label: const Text('Rate Contractor'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.amber[700],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _getContractorRating(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 50,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        if (snapshot.hasError) {
          print('Error in rating widget: ${snapshot.error}');
          return _buildRateButton(); // Show rate button on error
        }

        final bool alreadyRated = snapshot.hasData &&
            snapshot.data != null &&
            snapshot.data!['rating'] != null;

        print('Already rated: $alreadyRated');
        print('Rating data: ${snapshot.data}');

        if (alreadyRated) {
          return _buildExistingRating(snapshot.data!);
        } else {
          return _buildRateButton();
        }
      },
    );
  }
}
