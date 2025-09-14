import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import '../services/permission_service.dart';
import '../services/pose_detection_service_web.dart';
import '../services/workout_validation_service.dart';

class EnhancedWorkoutPage extends StatefulWidget {
  final int duration; // Duration in minutes
  final String locationAnalysis;
  
  const EnhancedWorkoutPage({
    super.key,
    required this.duration,
    required this.locationAnalysis,
  });

  @override
  State<EnhancedWorkoutPage> createState() => _EnhancedWorkoutPageState();
}

class _EnhancedWorkoutPageState extends State<EnhancedWorkoutPage> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isPaused = false;
  int _remainingSeconds = 0;
  Timer? _timer;
  
  // Workout validation
  final WorkoutValidationService _workoutValidator = WorkoutValidationService();
  final PoseDetectionServiceWeb _poseDetectionService = PoseDetectionServiceWeb();
  
  // Workout state
  bool _isWorkoutActive = false;
  WorkoutValidationResult? _currentValidation;
  String _workoutStatus = 'Ready to start';
  int _validReps = 0;
  double _workoutQuality = 0.0;
  
  // Workout data based on location analysis
  String _workoutName = 'Bicep Curls';
  String _workoutInstructions = 'Stand with feet hip-width apart. Hold your arms at your sides, then curl them up towards your shoulders. Lower them back down slowly.';
  String _formTips = 'Keep your core engaged and maintain a straight back throughout the movement.';

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.duration * 60; // Convert minutes to seconds
    _initializeCamera();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cameraController?.dispose();
    _poseDetectionService.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    // Check camera permission
    final hasPermission = await PermissionService.ensureCameraPermission();
    
    if (!hasPermission) {
      setState(() {
        _workoutStatus = 'Camera permission required';
      });
      return;
    }

    try {
      _cameras = await availableCameras();
      
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _workoutStatus = 'No cameras found';
        });
        return;
      }

      _cameraController = CameraController(
        _cameras![0],
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      
      setState(() {
        _isInitialized = true;
        _workoutStatus = 'Ready to start workout';
      });

    } catch (e) {
      setState(() {
        _workoutStatus = 'Error initializing camera: $e';
      });
    }
  }

  void _startWorkout() {
    if (!_isWorkoutActive) {
      _workoutValidator.startWorkout();
      _startTimer();
      _startPoseDetection();
      setState(() {
        _isWorkoutActive = true;
        _workoutStatus = 'Workout in progress!';
      });
    }
  }

  void _pauseWorkout() {
    setState(() {
      _isPaused = !_isPaused;
      _workoutStatus = _isPaused ? 'Workout paused' : 'Workout in progress!';
    });
    
    if (_isPaused) {
      _timer?.cancel();
    } else {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused && _remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else if (_remainingSeconds == 0) {
        _endWorkout();
      }
    });
  }

  void _startPoseDetection() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    _cameraController!.startImageStream(_processCameraImage);
  }

  Future<void> _processCameraImage(CameraImage cameraImage) async {
    if (!_isWorkoutActive || _isPaused) return;

    try {
      // Detect poses in the image
      final poses = await _poseDetectionService.detectPoses(
        cameraImage, 
        _cameraController!.description,
      );

      // Validate workout quality
      if (poses.isNotEmpty) {
        final validation = _workoutValidator.validateWorkout(poses);
        
        setState(() {
          _currentValidation = validation;
          _validReps = validation.reps;
          _workoutQuality = validation.quality;
          _workoutStatus = validation.message;
        });
      } else {
        setState(() {
          _workoutStatus = 'No pose detected. Position yourself in front of the camera.';
        });
      }

    } catch (e) {
      print('Error processing camera image: $e');
    }
  }

  void _endWorkout() {
    _timer?.cancel();
    _cameraController?.stopImageStream();
    
    final stats = _workoutValidator.getWorkoutStats();
    
    setState(() {
      _isWorkoutActive = false;
      _workoutStatus = 'Workout completed!';
    });

    _showWorkoutResults(stats);
  }

  void _showWorkoutResults(WorkoutStats stats) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          'Workout Complete!',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Valid Reps: ${stats.validReps}',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            Text(
              'Total Reps: ${stats.totalReps}',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            Text(
              'Workout Quality: ${(stats.intensity * 100).toInt()}%',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            Text(
              'Duration: ${stats.duration} seconds',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text(
              'Done',
              style: GoogleFonts.inter(color: const Color(0xFF6A0DAD)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Background
          if (_isInitialized && _cameraController != null)
            Positioned.fill(
              child: CameraPreview(_cameraController!),
            )
          else
            Container(
              color: const Color(0xFF121212),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: Color(0xFF6A0DAD),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _workoutStatus,
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
          
          // Transparent Black Overlay
          Container(
            color: Colors.black.withOpacity(0.4),
          ),
          
          // Content Overlay
          SafeArea(
            child: Column(
              children: [
                // Top Section with Timer and Status
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Timer
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF6A0DAD),
                            width: 2,
                          ),
                        ),
                        child: Text(
                          _formatTime(_remainingSeconds),
                          style: GoogleFonts.inter(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Workout Status
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _currentValidation?.isValid == true 
                            ? Colors.green.withOpacity(0.8)
                            : Colors.orange.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _workoutStatus,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Bottom Section with Workout Info and Controls
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Workout Stats
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF6A0DAD),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text(
                                  'Valid Reps',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF9E9E9E),
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '$_validReps',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                  'Quality',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF9E9E9E),
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '${(_workoutQuality * 100).toInt()}%',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF6A0DAD),
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Control Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          if (!_isWorkoutActive)
                            ElevatedButton(
                              onPressed: _startWorkout,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6A0DAD),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'Start Workout',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          
                          if (_isWorkoutActive)
                            ElevatedButton(
                              onPressed: _pauseWorkout,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isPaused 
                                  ? Colors.green 
                                  : Colors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                _isPaused ? 'Resume' : 'Pause',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          
                          if (_isWorkoutActive)
                            ElevatedButton(
                              onPressed: _endWorkout,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'End Workout',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
