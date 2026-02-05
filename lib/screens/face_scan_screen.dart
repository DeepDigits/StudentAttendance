import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:attendance_tracking/config/api_config.dart';
import 'package:attendance_tracking/utils/snackbar_utils.dart';
import 'package:path_provider/path_provider.dart';

class FaceScanScreen extends StatefulWidget {
  final String rollNumber;
  final String studentName;

  const FaceScanScreen({
    super.key,
    required this.rollNumber,
    required this.studentName,
  });

  @override
  State<FaceScanScreen> createState() => _FaceScanScreenState();
}

class _FaceScanScreenState extends State<FaceScanScreen>
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isCapturing = false;
  bool _isUploading = false;
  bool _isTraining = false;
  bool _isComplete = false;
  bool _hasError = false;
  String _statusMessage = 'Position your face in the frame';
  int _capturedCount = 0;
  final int _requiredImages = 10;
  List<String> _capturedImagePaths = [];

  // Animation controllers
  late AnimationController _scanAnimationController;
  late AnimationController _pulseAnimationController;
  late Animation<double> _scanAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeCamera();
  }

  void _initializeAnimations() {
    // Scan line animation (moves up and down)
    _scanAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _scanAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Pulse animation for the frame
    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _hasError = true;
          _statusMessage = 'No cameras available on this device';
        });
        return;
      }

      // Use front camera for face capture
      CameraDescription? frontCamera;
      for (var camera in _cameras!) {
        if (camera.lensDirection == CameraLensDirection.front) {
          frontCamera = camera;
          break;
        }
      }

      // Fallback to first camera if no front camera
      final selectedCamera = frontCamera ?? _cameras!.first;

      _cameraController = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _statusMessage = 'Failed to initialize camera: $e';
      });
    }
  }

  Future<void> _startCapturing() async {
    if (_isCapturing || _cameraController == null) return;

    setState(() {
      _isCapturing = true;
      _capturedCount = 0;
      _capturedImagePaths.clear();
      _statusMessage = 'Capturing face images...';
    });

    // Capture multiple images with delay
    for (int i = 0; i < _requiredImages; i++) {
      if (!mounted || !_isCapturing) break;

      try {
        // Add slight delay between captures for different angles
        await Future.delayed(const Duration(milliseconds: 500));

        final XFile image = await _cameraController!.takePicture();
        _capturedImagePaths.add(image.path);

        setState(() {
          _capturedCount = i + 1;
          _statusMessage =
              'Captured $_capturedCount of $_requiredImages images\nMove your head slightly for variations';
        });
      } catch (e) {
        debugPrint('Error capturing image: $e');
      }
    }

    if (_capturedImagePaths.isNotEmpty) {
      await _uploadAndTrain();
    } else {
      setState(() {
        _isCapturing = false;
        _hasError = true;
        _statusMessage = 'Failed to capture images. Please try again.';
      });
    }
  }

  Future<void> _uploadAndTrain() async {
    setState(() {
      _isCapturing = false;
      _isUploading = true;
      _statusMessage = 'Uploading face images...';
    });

    try {
      // Upload images to server
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/upload-face-images/');
      final request = http.MultipartRequest('POST', uri);

      request.fields['roll_number'] = widget.rollNumber;

      for (int i = 0; i < _capturedImagePaths.length; i++) {
        final file = File(_capturedImagePaths[i]);
        final bytes = await file.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'images',
            bytes,
            filename: 'face_$i.jpg',
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Upload failed');
      }

      final uploadResult = json.decode(response.body);
      debugPrint('Upload result: $uploadResult');

      // Start training
      setState(() {
        _isUploading = false;
        _isTraining = true;
        _statusMessage = 'Training face recognition model...';
      });

      await _trainModel();
    } catch (e) {
      setState(() {
        _isUploading = false;
        _hasError = true;
        _statusMessage = 'Upload failed: $e';
      });
    } finally {
      // Clean up temporary files
      for (String path in _capturedImagePaths) {
        try {
          final file = File(path);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          debugPrint('Error deleting temp file: $e');
        }
      }
    }
  }

  Future<void> _trainModel() async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/train-model/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'student_id': widget.rollNumber}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('Train result: $data');

        setState(() {
          _isTraining = false;
          _isComplete = true;
          _statusMessage =
              'Face registration complete!\nYour face has been trained successfully.';
        });

        // Show success message
        ToastUtils.showSuccessToast(
          'Face registration completed successfully!',
        );

        // Wait a moment then navigate back
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } else {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Training failed');
      }
    } catch (e) {
      setState(() {
        _isTraining = false;
        _hasError = true;
        _statusMessage = 'Training failed: $e';
      });
    }
  }

  void _retryCapture() {
    setState(() {
      _hasError = false;
      _isCapturing = false;
      _isUploading = false;
      _isTraining = false;
      _capturedCount = 0;
      _capturedImagePaths.clear();
      _statusMessage = 'Position your face in the frame';
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _scanAnimationController.dispose();
    _pulseAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(theme, isDark),

            // Camera preview with overlay
            Expanded(child: _buildCameraSection(theme, isDark, primaryColor)),

            // Bottom controls
            _buildBottomControls(theme, isDark, primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.black,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => _showExitConfirmation(),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'Face Registration',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hello, ${widget.studentName}',
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(width: 48), // Balance the close button
        ],
      ),
    );
  }

  Widget _buildCameraSection(ThemeData theme, bool isDark, Color primaryColor) {
    if (_hasError) {
      return _buildErrorView(primaryColor);
    }

    if (_isComplete) {
      return _buildSuccessView(primaryColor);
    }

    if (!_isCameraInitialized) {
      return _buildLoadingView();
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        // Camera preview
        if (_cameraController != null && _cameraController!.value.isInitialized)
          Transform.scale(
            scale: 1.0,
            child: Center(child: CameraPreview(_cameraController!)),
          ),

        // Overlay with face frame
        _buildScanOverlay(primaryColor),

        // Status message
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
            ),
          ),
        ),

        // Progress indicator during capture/upload/training
        if (_isCapturing || _isUploading || _isTraining)
          _buildProgressOverlay(primaryColor),
      ],
    );
  }

  Widget _buildScanOverlay(Color primaryColor) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return CustomPaint(
          painter: FaceScanPainter(
            scanProgress: _scanAnimation.value,
            pulseScale: _pulseAnimation.value,
            primaryColor: primaryColor,
            isCapturing: _isCapturing,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildProgressOverlay(Color primaryColor) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isCapturing)
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      value: _capturedCount / _requiredImages,
                      strokeWidth: 6,
                      backgroundColor: Colors.white24,
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                  ),
                  Text(
                    '$_capturedCount/$_requiredImages',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            else
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            const SizedBox(height: 20),
            Text(
              _isCapturing
                  ? 'Capturing face images...'
                  : _isUploading
                  ? 'Uploading images...'
                  : 'Training model...',
              style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text('Initializing camera...', style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildErrorView(Color primaryColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red.shade400),
            const SizedBox(height: 24),
            Text(
              'Error',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _retryCapture,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView(Color primaryColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.shade600,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 32),
            Text(
              'Success!',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls(
    ThemeData theme,
    bool isDark,
    Color primaryColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.black,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress indicator
          if (!_isComplete && !_hasError)
            Column(
              children: [
                LinearProgressIndicator(
                  value: _capturedCount / _requiredImages,
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
                const SizedBox(height: 8),
                Text(
                  'Images: $_capturedCount / $_requiredImages',
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 20),
              ],
            ),

          // Capture button
          if (!_isCapturing &&
              !_isUploading &&
              !_isTraining &&
              !_isComplete &&
              !_hasError)
            GestureDetector(
              onTap: _startCapturing,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryColor,
                  ),
                  child: const Icon(Icons.face, color: Colors.white, size: 36),
                ),
              ),
            ),

          const SizedBox(height: 8),
          if (!_isCapturing &&
              !_isUploading &&
              !_isTraining &&
              !_isComplete &&
              !_hasError)
            Text(
              'Tap to start face capture',
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
            ),
        ],
      ),
    );
  }

  void _showExitConfirmation() {
    if (_isComplete) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Face Registration?'),
        content: const Text(
          'Your registration is incomplete. You can complete face registration later from your profile.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('Skip for Now'),
          ),
        ],
      ),
    );
  }
}

// Custom painter for the face scan animation
class FaceScanPainter extends CustomPainter {
  final double scanProgress;
  final double pulseScale;
  final Color primaryColor;
  final bool isCapturing;

  FaceScanPainter({
    required this.scanProgress,
    required this.pulseScale,
    required this.primaryColor,
    required this.isCapturing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final faceFrameSize = size.width * 0.7 * pulseScale;
    final faceFrameRect = Rect.fromCenter(
      center: center,
      width: faceFrameSize,
      height: faceFrameSize * 1.3,
    );

    // Draw semi-transparent overlay outside the face frame
    final overlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(faceFrameRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, overlayPaint);

    // Draw face frame border
    final framePaint = Paint()
      ..color = isCapturing ? Colors.green : primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawOval(faceFrameRect, framePaint);

    // Draw corner brackets
    final bracketPaint = Paint()
      ..color = isCapturing ? Colors.green : primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final bracketLength = faceFrameSize * 0.15;
    final corners = [
      // Top-left
      [
        Offset(faceFrameRect.left + bracketLength, faceFrameRect.top),
        Offset(faceFrameRect.left, faceFrameRect.top),
        Offset(faceFrameRect.left, faceFrameRect.top + bracketLength * 1.3),
      ],
      // Top-right
      [
        Offset(faceFrameRect.right - bracketLength, faceFrameRect.top),
        Offset(faceFrameRect.right, faceFrameRect.top),
        Offset(faceFrameRect.right, faceFrameRect.top + bracketLength * 1.3),
      ],
      // Bottom-left
      [
        Offset(faceFrameRect.left + bracketLength, faceFrameRect.bottom),
        Offset(faceFrameRect.left, faceFrameRect.bottom),
        Offset(faceFrameRect.left, faceFrameRect.bottom - bracketLength * 1.3),
      ],
      // Bottom-right
      [
        Offset(faceFrameRect.right - bracketLength, faceFrameRect.bottom),
        Offset(faceFrameRect.right, faceFrameRect.bottom),
        Offset(faceFrameRect.right, faceFrameRect.bottom - bracketLength * 1.3),
      ],
    ];

    for (var corner in corners) {
      canvas.drawLine(corner[0], corner[1], bracketPaint);
      canvas.drawLine(corner[1], corner[2], bracketPaint);
    }

    // Draw scanning line
    if (!isCapturing) {
      final scanY = faceFrameRect.top + (faceFrameRect.height * scanProgress);
      final scanLinePaint = Paint()
        ..shader =
            LinearGradient(
              colors: [
                primaryColor.withOpacity(0),
                primaryColor.withOpacity(0.8),
                primaryColor.withOpacity(0),
              ],
            ).createShader(
              Rect.fromLTWH(
                faceFrameRect.left,
                scanY - 2,
                faceFrameRect.width,
                4,
              ),
            )
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromLTWH(
          faceFrameRect.left + 20,
          scanY - 2,
          faceFrameRect.width - 40,
          4,
        ),
        scanLinePaint,
      );
    }
  }

  @override
  bool shouldRepaint(FaceScanPainter oldDelegate) {
    return oldDelegate.scanProgress != scanProgress ||
        oldDelegate.pulseScale != pulseScale ||
        oldDelegate.isCapturing != isCapturing;
  }
}
