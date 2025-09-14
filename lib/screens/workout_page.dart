import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import '../services/pose_detection_service.dart';
import '../services/motion_detection_service.dart';

class WorkoutPage extends StatefulWidget {
  final int duration; // Duration in minutes
  final String locationAnalysis;
  final bool enablePoseDetection;
  
  const WorkoutPage({
    super.key,
    required this.duration,
    required this.locationAnalysis,
    this.enablePoseDetection = false,
  });

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isPaused = false;
  int _remainingSeconds = 0;
  Timer? _timer;
  
  // Motion detection
  final PoseDetectionService _poseDetectionService = PoseDetectionService();
  final MotionDetectionService _motionDetectionService = MotionDetectionService();
  
  // Workout state
  bool _isWorkoutActive = false;
  String _workoutStatus = 'Ready to start';
  bool _isMoving = false;
  DateTime? _lastMovementTime;
  int _repCount = 0;
  
  // Workout data based on location analysis
  String _workoutName = 'Bicep Curls';
  String _workoutInstructions = 'Stand with feet hip-width apart. Hold your arms at your sides, then curl them up towards your shoulders. Lower them back down slowly.';
  String _formTips = 'Keep your core engaged and maintain a straight back throughout the movement.';

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.duration * 60; // Convert minutes to seconds
    // Don't initialize camera here, wait for workout to start
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cameraController?.dispose();
    _poseDetectionService.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    if (kIsWeb) {
      setState(() {
        _isInitialized = true;
        _workoutStatus = 'Demo Mode: Camera not supported on web';
      });
      return;
    }
    
    try {
      // Dispose of any existing camera controller
      await _cameraController?.dispose();
      _cameraController = null;

      print('Getting available cameras...');
      _cameras = await availableCameras();
      if (_cameras!.isEmpty) {
        throw Exception('No cameras found');
      }
      print('Found ${_cameras!.length} cameras');

      // Try to get the front camera first
      final frontCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );
      print('Selected camera: ${frontCamera.name}');

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      
      print('Initializing camera controller...');
      await _cameraController!.initialize();
      print('Camera controller initialized');
      
      if (!mounted) return;

      setState(() {
        _isInitialized = true;
        print('Camera initialization completed successfully');
      });

    } catch (e) {
      print('Error initializing camera: $e');
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _workoutStatus = 'Error: Camera initialization failed - $e';
        });
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused && _remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else if (_remainingSeconds == 0) {
        _timer?.cancel();
        _endWorkout();
      }
    });
  }

  Future<void> _startWorkout() async {
    if (!_isWorkoutActive) {
      setState(() {
        _isWorkoutActive = true;
        _workoutStatus = 'Starting workout... Get ready!';
      });

      // Re-initialize camera to ensure it's ready
      await _initializeCamera();
      
      if (!kIsWeb) {
        await _startPoseDetection();
      }
      
      _motionDetectionService.reset();
      _startTimer();
    }
  }

  Future<void> _startPoseDetection() async {
    if (kIsWeb) {
      // Camera not supported on web, use demo mode
      setState(() {
        _workoutStatus = 'Demo Mode: Camera not supported on web';
      });
      return;
    }
    
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      print('Camera not initialized when trying to start pose detection');
      return;
    }

    try {
      await _cameraController!.startImageStream(_processCameraImage);
      print('Camera stream started successfully');
    } catch (e) {
      print('Error starting camera stream: $e');
      setState(() {
        _workoutStatus = 'Error starting camera';
      });
    }
  }

  Future<void> _processCameraImage(CameraImage cameraImage) async {
    if (!_isWorkoutActive || _isPaused) return;

    try {
      // Detect poses in the image
      final poses = await _poseDetectionService.detectPoses(
        cameraImage, 
        _cameraController!.description,
      );

      // Check for motion
      if (poses.isNotEmpty) {
        final isMoving = _motionDetectionService.isMoving(poses);
        setState(() {
          _isMoving = isMoving;
          _workoutStatus = isMoving 
              ? 'Movement detected! Keep going!' 
              : 'No movement detected. Keep moving!';
          _repCount = _motionDetectionService.getRepCount();
        });
      } else {
        setState(() {
          _isMoving = false;
          _workoutStatus = 'No person detected. Position yourself in front of the camera.';
        });
      }

    } catch (e) {
      print('Error processing camera image: $e');
    }
  }

  void _endWorkout() {
    _timer?.cancel();
    if (!kIsWeb) {
      _cameraController?.stopImageStream();
    }
    
    setState(() {
      _isWorkoutActive = false;
      _workoutStatus = 'Workout completed!';
    });

    _showWorkoutCompleteDialog();
  }

  void _demoMode() {
    if (!_isWorkoutActive) {
      _startTimer();
      setState(() {
        _isWorkoutActive = true;
        _workoutStatus = 'Demo Mode: Simulating workout...';
      });
    }
  }


  void _generateWorkoutFromLocation() {
    // Generate workout based on location analysis
    if (widget.locationAnalysis.toLowerCase().contains('living room')) {
      _workoutName = 'Standing Lunges';
      _workoutInstructions = 'Stand with feet hip-width apart. Step forward with one leg, lowering your hips until both knees are bent at about a 90-degree angle. Keep your front knee directly above your ankle. Push back up to starting position.';
      _formTips = 'Keep your core engaged and maintain a straight back throughout the movement.';
    } else if (widget.locationAnalysis.toLowerCase().contains('bedroom')) {
      _workoutName = 'Bedroom Yoga Flow';
      _workoutInstructions = 'Start in a comfortable seated position. Gently stretch your arms overhead, then fold forward. Move through gentle twists and stretches.';
      _formTips = 'Focus on your breathing and move slowly with control.';
    } else if (widget.locationAnalysis.toLowerCase().contains('office')) {
      _workoutName = 'Desk Stretches';
      _workoutInstructions = 'Sit tall in your chair. Roll your shoulders back and down. Gently turn your head from side to side. Stretch your arms overhead.';
      _formTips = 'Keep movements slow and controlled. Breathe deeply throughout.';
    } else if (widget.locationAnalysis.toLowerCase().contains('kitchen')) {
      _workoutName = 'Kitchen Counter Push-ups';
      _workoutInstructions = 'Stand facing your kitchen counter. Place your hands on the edge, shoulder-width apart. Lower your chest toward the counter, then push back up.';
      _formTips = 'Keep your body in a straight line from head to heels.';
    } else if (widget.locationAnalysis.toLowerCase().contains('outdoor')) {
      _workoutName = 'Outdoor Cardio';
      _workoutInstructions = 'Start with marching in place, then progress to jumping jacks. Add some high knees and arm circles for a full-body warm-up.';
      _formTips = 'Maintain good posture and land softly on your feet.';
    }
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  void _showWorkoutCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF121212),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Workout Complete!',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'Great job! You\'ve completed your ${widget.duration}-minute workout.',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF6A0DAD),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(context).pop(); // Go back to home
                  },
                  child: Center(
                    child: Text(
                      'Done',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF6A0DAD),
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
                // Top Section
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
                
                // Center Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        
                        // Timer
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF6A0DAD),
                              width: 4,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _formatTime(_remainingSeconds),
                              style: GoogleFonts.inter(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // Workout Status
                        if (_isWorkoutActive) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _isMoving
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
                          
                          const SizedBox(height: 20),
                          
                          // Workout Stats
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    'Status',
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF9E9E9E),
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    _isMoving ? 'Moving' : 'Still',
                                    style: GoogleFonts.inter(
                                      color: _isMoving ? Colors.green : Colors.orange,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ] else ...[
                          // Start Workout Button
                          ElevatedButton(
                            onPressed: _startWorkout,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6A0DAD),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Start Workout',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          
                          // Demo Mode Button for Web
                          if (kIsWeb) ...[
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _demoMode,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Demo Mode',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                        
                        const SizedBox(height: 40),
                        
                      ],
                    ),
                  ),
                ),
                
                // Bottom Buttons
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      // Pause Button
                      Expanded(
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: _togglePause,
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _isPaused ? Icons.play_arrow : Icons.pause,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _isPaused ? 'Resume' : 'Pause',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Done Button
                      Expanded(
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6A0DAD),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: _showWorkoutCompleteDialog,
                              child: Center(
                                child: Text(
                                  'Done',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
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