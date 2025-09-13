import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';

class WorkoutPage extends StatefulWidget {
  final int duration; // Duration in minutes
  final String locationAnalysis;
  
  const WorkoutPage({
    super.key,
    required this.duration,
    required this.locationAnalysis,
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
  
  // Workout data based on location analysis
  String _workoutName = 'Standing Lunges';
  String _workoutInstructions = 'Stand with feet hip-width apart. Step forward with one leg, lowering your hips until both knees are bent at about a 90-degree angle. Keep your front knee directly above your ankle. Push back up to starting position.';
  String _formTips = 'Keep your core engaged and maintain a straight back throughout the movement.';

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.duration * 60; // Convert minutes to seconds
    _initializeCamera();
    _startTimer();
    _generateWorkoutFromLocation();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras!.isNotEmpty) {
      _cameraController = CameraController(
        _cameras![0],
        ResolutionPreset.medium,
        enableAudio: false,
      );
      
      await _cameraController!.initialize();
      setState(() {
        _isInitialized = true;
      });
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
        _showWorkoutCompleteDialog();
      }
    });
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Workout in Progress',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Center Content
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Workout Name
                      Text(
                        _workoutName,
                        style: GoogleFonts.inter(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 40),
                      
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
                      
                      // Instructions
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Instructions',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _workoutInstructions,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Form Tips: $_formTips',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: const Color(0xFF6A0DAD),
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
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
