import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import '../models/exercise_analysis.dart';
import '../services/workout_service.dart';
import '../services/person_detection_service.dart';
import '../widgets/person_detection_warning.dart';

class WorkoutInProgressPage extends StatefulWidget {
  final ExerciseSuggestion exercise;
  final String imagePath;
  final int duration;
  final List<String> detectedObjects;

  const WorkoutInProgressPage({
    Key? key,
    required this.exercise,
    required this.imagePath,
    required this.duration,
    required this.detectedObjects,
  }) : super(key: key);

  @override
  State<WorkoutInProgressPage> createState() => _WorkoutInProgressPageState();
}

class _WorkoutInProgressPageState extends State<WorkoutInProgressPage> with TickerProviderStateMixin {
  Timer? _timer;
  int _countdownSeconds = 60; // 1 minute countdown
  bool _isPaused = false;
  bool _isCompleted = false;
  bool _isExerciseDetailsExpanded = true; // Toggle for exercise details
  bool _isCountdownFinished = false;
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  final WorkoutService _workoutService = WorkoutService();
  final PersonDetectionService _personDetectionService = PersonDetectionService();
  bool _isPersonDetected = true;
  
  // Animation controllers for celebration
  late AnimationController _celebrationController;
  late AnimationController _pulseController;
  late Animation<double> _celebrationAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializePersonDetection();
    _startTimer();
    _initializeCamera();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cameraController?.dispose();
    _celebrationController.dispose();
    _pulseController.dispose();
    _personDetectionService.dispose();
    super.dispose();
  }

  void _initializePersonDetection() {
    _personDetectionService.onPersonDetectionChanged = (bool isDetected) {
      setState(() {
        _isPersonDetected = isDetected;
      });
    };
    
    _personDetectionService.onPersonLost = () {
      print('⚠️ Person lost - showing warning');
    };
    
    _personDetectionService.onPersonFound = () {
      print('✅ Person found - hiding warning');
    };
  }

  void _initializeAnimations() {
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _celebrationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _celebrationController,
      curve: Curves.elasticOut,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.medium,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        setState(() {
          _isCameraInitialized = true;
        });
        
        // Start person detection after camera is initialized
        _personDetectionService.startDetection(_cameraController!);
      }
    } catch (e) {
      print('❌ Error initializing camera: $e');
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused && !_isCompleted && !_isCountdownFinished) {
        setState(() {
          _countdownSeconds--;
          
          // Play sound effect for last 10 seconds
          if (_countdownSeconds <= 10 && _countdownSeconds > 0) {
            HapticFeedback.lightImpact();
          }
          
          // Countdown finished
          if (_countdownSeconds <= 0) {
            _countdownSeconds = 0;
            _isCountdownFinished = true;
            _onCountdownFinished();
          }
        });
      }
    });
  }

  void _onCountdownFinished() {
    // Play celebration sound
    HapticFeedback.heavyImpact();
    
    // Start celebration animations
    _celebrationController.forward();
    _pulseController.repeat(reverse: true);
    
    // Auto-complete workout after celebration
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _completeWorkout();
      }
    });
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  void _toggleExerciseDetails() {
    setState(() {
      _isExerciseDetailsExpanded = !_isExerciseDetailsExpanded;
    });
  }

  void _completeWorkout() async {
    setState(() {
      _isCompleted = true;
    });
    _timer?.cancel();
    
    // Calculate actual workout duration (60 seconds - remaining countdown)
    final actualDuration = 60 - _countdownSeconds;
    
    // Save workout to Firestore
    try {
      await _workoutService.saveCompletedWorkout(
        exerciseName: widget.exercise.exercise,
        instructions: widget.exercise.instructions,
        duration: actualDuration,
        detectedObjects: widget.detectedObjects,
        imagePath: widget.imagePath,
      );
      print('✅ Workout saved to Firestore successfully');
    } catch (e) {
      print('❌ Error saving workout: $e');
    }
    
    _showCompletionDialog();
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.green,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Workout Completed!',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Duration: ${_formatDuration(60 - _countdownSeconds)}',
                style: GoogleFonts.inter(
                  color: const Color(0xFF9E9E9E),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to previous screen
              },
              child: Text(
                'Done',
                style: GoogleFonts.inter(
                  color: const Color(0xFF6A0DAD),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          // Live camera background
          if (_isCameraInitialized && _cameraController != null)
            Positioned.fill(
              child: Opacity(
                opacity: 0.3,
                child: CameraPreview(_cameraController!),
              ),
            ),
          
          // Main content overlay
          SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Workout in Progress',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Timer Display
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isCountdownFinished ? _pulseAnimation.value : 1.0,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: _isCountdownFinished 
                              ? Colors.green.withOpacity(0.2)
                              : const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(20),
                          border: _isCountdownFinished 
                              ? Border.all(color: Colors.green, width: 2)
                              : null,
                        ),
                        child: Column(
                          children: [
                            Text(
                              _formatDuration(_countdownSeconds),
                              style: GoogleFonts.inter(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: _isCountdownFinished 
                                    ? Colors.green
                                    : _isPaused 
                                        ? const Color(0xFFFFC107) 
                                        : _countdownSeconds <= 10 
                                            ? Colors.red 
                                            : const Color(0xFF6A0DAD),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isCountdownFinished 
                                  ? 'COMPLETED! 🎉'
                                  : _isPaused 
                                      ? 'PAUSED' 
                                      : _countdownSeconds <= 10 
                                          ? 'ALMOST DONE!'
                                          : 'WORKING OUT',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _isCountdownFinished 
                                    ? Colors.green
                                    : _isPaused 
                                        ? const Color(0xFFFFC107) 
                                        : _countdownSeconds <= 10 
                                            ? Colors.red 
                                            : const Color(0xFF6A0DAD),
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Celebration Animation
                if (_isCountdownFinished)
                  AnimatedBuilder(
                    animation: _celebrationAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _celebrationAnimation.value,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.green.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.celebration,
                                color: Colors.green,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Great job! Workout completed!',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 24),

                // Exercise Info Card (Collapsible)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  height: _isExerciseDetailsExpanded ? null : 80,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: _isExerciseDetailsExpanded 
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Exercise Name with Toggle Button
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF6A0DAD).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.fitness_center,
                                      color: Color(0xFF6A0DAD),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      widget.exercise.exercise,
                                      style: GoogleFonts.inter(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: _toggleExerciseDetails,
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2A2A2A),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        _isExerciseDetailsExpanded 
                                            ? Icons.keyboard_arrow_up 
                                            : Icons.keyboard_arrow_down,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // Instructions
                              Text(
                                'Instructions',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),

                              const SizedBox(height: 12),

                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2A2A2A),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  widget.exercise.instructions,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    color: Colors.white,
                                    height: 1.5,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Detected Objects
                              Text(
                                'Environment',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),

                              const SizedBox(height: 12),

                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: widget.detectedObjects.map((object) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF6A0DAD).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: const Color(0xFF6A0DAD).withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      object,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: const Color(0xFF6A0DAD),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6A0DAD).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.fitness_center,
                                  color: Color(0xFF6A0DAD),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  widget.exercise.exercise,
                                  style: GoogleFonts.inter(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: _toggleExerciseDetails,
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2A2A2A),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _isExerciseDetailsExpanded 
                                        ? Icons.keyboard_arrow_up 
                                        : Icons.keyboard_arrow_down,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const Spacer(),

                // Control Buttons (Always Visible)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      // Pause/Resume Button
                      Expanded(
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: _isPaused 
                                ? const Color(0xFF6A0DAD)
                                : const Color(0xFFFFC107),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
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

                      // Complete Button
                      Expanded(
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: _completeWorkout,
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Complete',
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
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
          
          // Person Detection Warning Overlay
          PersonDetectionWarning(
            isVisible: !_isPersonDetected,
            onDismiss: () {
              setState(() {
                _isPersonDetected = true;
              });
            },
          ),
        ],
      ),
    );
  }
}