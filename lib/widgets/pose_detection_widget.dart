import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';
import '../services/permission_service.dart';
import '../services/pose_detection_service.dart';
import '../services/pose_detection_service_web.dart';
import '../services/gesture_recognition_service.dart';

/// Widget that handles camera preview and real-time pose detection
class PoseDetectionWidget extends StatefulWidget {
  const PoseDetectionWidget({super.key});

  @override
  State<PoseDetectionWidget> createState() => _PoseDetectionWidgetState();
}

class _PoseDetectionWidgetState extends State<PoseDetectionWidget> {
  // Camera and pose detection
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isProcessing = false;

  // Services
  late dynamic _poseDetectionService;
  final GestureRecognitionService _gestureRecognitionService = GestureRecognitionService();

  // UI state
  String _statusMessage = 'Initializing camera...';
  String _exerciseFeedback = 'Ready for workout';
  int _exerciseCount = 0;
  bool _hasPermission = false;
  bool _poseDetectionAvailable = true;

  @override
  void initState() {
    super.initState();
    // Initialize the appropriate pose detection service based on platform
    if (kIsWeb) {
      _poseDetectionService = PoseDetectionServiceWeb();
    } else {
      _poseDetectionService = PoseDetectionService();
    }
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _poseDetectionService.dispose();
    super.dispose();
  }

  /// Initialize camera and check permissions
  Future<void> _initializeCamera() async {
    try {
      // Check camera permission
      final hasPermission = await PermissionService.ensureCameraPermission();
      
      if (!hasPermission) {
        setState(() {
          _statusMessage = 'Camera permission denied. Please enable in settings.';
          _hasPermission = false;
        });
        return;
      }

      setState(() {
        _hasPermission = true;
        _statusMessage = 'Loading camera...';
      });

      // Get available cameras
      _cameras = await availableCameras();
      
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _statusMessage = 'No cameras found on this device.';
        });
        return;
      }

      // Initialize camera controller with front camera
      _cameraController = CameraController(
        _cameras![0], // Use front camera
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();
      
      // Start image stream for pose detection
      _startImageStream();
      
      setState(() {
        _isInitialized = true;
        _statusMessage = 'Camera ready! Position yourself in front of the camera.';
      });

    } catch (e) {
      setState(() {
        _statusMessage = 'Error initializing camera: $e';
      });
    }
  }

  /// Start processing camera images for pose detection
  void _startImageStream() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    _cameraController!.startImageStream(_processCameraImage);
  }

  /// Process camera images for pose detection
  Future<void> _processCameraImage(CameraImage cameraImage) async {
    if (_isProcessing || _cameraController == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Detect poses in the image
      final poses = await _poseDetectionService.detectPoses(
        cameraImage, 
        _cameraController!.description,
      );

      // Process poses for gesture recognition
      if (poses.isNotEmpty) {
        final feedback = _gestureRecognitionService.detectGesture(poses);
        
        setState(() {
          _exerciseFeedback = feedback;
          _exerciseCount = _gestureRecognitionService.bicepCurlCount;
        });
      } else {
        setState(() {
          _exerciseFeedback = 'No pose detected. Position yourself in front of the camera.';
        });
      }

    } catch (e) {
      print('Error processing camera image: $e');
      // Fallback to demo mode if pose detection fails
      setState(() {
        _poseDetectionAvailable = false;
        _exerciseFeedback = 'Demo Mode: Pose detection not available on this platform.';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  /// Reset exercise count
  void _resetCount() {
    _gestureRecognitionService.resetCount();
    setState(() {
      _exerciseCount = 0;
      _exerciseFeedback = 'Ready for workout';
    });
  }

  /// Demo mode - simulate exercise detection
  void _demoMode() {
    setState(() {
      _exerciseCount++;
      _exerciseFeedback = 'Demo Mode: Exercise detected! Count: $_exerciseCount';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          if (_isInitialized && _cameraController != null)
            Positioned.fill(
              child: CameraPreview(_cameraController!),
            )
          else
            Container(
              color: Colors.black,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: Color(0xFF6A0DAD),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _statusMessage,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

          // Overlay UI
          if (_isInitialized)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                    stops: const [0.0, 0.3, 1.0],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      // Top section with status
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF6A0DAD),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'AI Pose Detection',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _exerciseFeedback,
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF9E9E9E),
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Bottom section with count and controls
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF6A0DAD),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              // Exercise count
                              Text(
                                'Bicep Curls',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$_exerciseCount',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF6A0DAD),
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Action buttons
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton(
                                    onPressed: _resetCount,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF6A0DAD),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      'Reset',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  if (!_poseDetectionAvailable)
                                    ElevatedButton(
                                      onPressed: _demoMode,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFFFC107),
                                        foregroundColor: Colors.black,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Text(
                                        'Demo',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Permission denied overlay
          if (!_hasPermission)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.9),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.camera_alt_outlined,
                          size: 64,
                          color: Color(0xFF6A0DAD),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Camera Permission Required',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'This app needs camera access to detect your poses during workouts and provide real-time feedback.',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF9E9E9E),
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: () async {
                            await PermissionService.openAppSettings();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6A0DAD),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Open Settings',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
