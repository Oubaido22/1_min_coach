import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
<<<<<<< HEAD
import '../services/exercise_analysis_service.dart';
import '../models/exercise_analysis.dart';
import 'exercise_suggestion_page.dart';
=======
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import '../services/camera_service.dart';
import '../services/image_picker_service.dart';
import 'workout_page.dart';
>>>>>>> a541a6609ceede26cd85bf7d3b238e314b05a392

class CameraWidget extends StatefulWidget {
  const CameraWidget({super.key});

  @override
  State<CameraWidget> createState() => _CameraWidgetState();
}

class _CameraWidgetState extends State<CameraWidget> {
  bool _isInitialized = false;
  bool _isAnalyzing = false;
  ExerciseAnalysis? _analysisResult;
  int _selectedDuration = 3; // Default to 3 minutes
<<<<<<< HEAD
  bool _isUsingMockData = false;
  final ExerciseAnalysisService _analysisService = ExerciseAnalysisService();
=======
  XFile? _selectedImage;
>>>>>>> a541a6609ceede26cd85bf7d3b238e314b05a392

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      if (kIsWeb) {
        // Sur le web, on ne peut pas initialiser la caméra
        setState(() {
          _isInitialized = true; // On considère comme initialisé pour permettre l'utilisation d'image_picker
        });
        return;
      }
      
      final controller = await CameraService.initializeCamera();
      if (controller != null) {
        setState(() {
          _isInitialized = true;
        });
      } else {
        _showErrorDialog('Impossible d\'initialiser la caméra. Vérifiez les permissions.');
      }
    } catch (e) {
      _showErrorDialog('Erreur lors de l\'initialisation de la caméra: $e');
    }
  }

  @override
  void dispose() {
    CameraService.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (!_isInitialized) {
      _showErrorDialog('Caméra non initialisée');
      return;
    }

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final XFile? image = await CameraService.takePicture();
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
        await _analyzeImage(image.path);
      } else {
        setState(() {
          _isAnalyzing = false;
        });
        _showErrorDialog('Impossible de prendre la photo');
      }
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      _showErrorDialog('Erreur lors de la prise de photo: $e');
    }
  }

  Future<void> _selectImageFromGallery() async {
    setState(() {
      _isAnalyzing = true;
    });

    try {
      final XFile? image = await ImagePickerService.pickImageFromGallery();
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
        await _analyzeImage(image.path);
      } else {
        setState(() {
          _isAnalyzing = false;
        });
        _showErrorDialog('Aucune image sélectionnée');
      }
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      _showErrorDialog('Erreur lors de la sélection d\'image: $e');
    }
  }

  Future<void> _analyzeImage(String imagePath) async {
    try {
      print('🔍 Starting image analysis...');
      
<<<<<<< HEAD
      // Convert duration from minutes to seconds
      final durationInSeconds = _selectedDuration * 60;
      
      // Test API connection first
      final isApiAvailable = await _analysisService.testApiConnection();
      
      // Analyze the image using the exercise analysis service
      final analysis = await _analysisService.analyzeWorkoutPictureWithRetry(
        imageFile: File(imagePath),
        duration: durationInSeconds,
      );
=======
      // Mock analysis result
      final mockResults = [
        "Salon détecté - Parfait pour les exercices debout!",
        "Chambre détectée - Idéal pour le yoga et les étirements!",
        "Bureau détecté - Parfait pour les exercices de bureau!",
        "Cuisine détectée - Idéal pour les exercices au comptoir!",
        "Espace extérieur détecté - Parfait pour le cardio!",
      ];
>>>>>>> a541a6609ceede26cd85bf7d3b238e314b05a392
      
      setState(() {
        _analysisResult = analysis;
        _isAnalyzing = false;
        _isUsingMockData = !isApiAvailable;
      });
      
      print('✅ Image analysis completed successfully');
      print('📊 Using ${_isUsingMockData ? "mock" : "real"} data');
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _isUsingMockData = true;
      });
      _showErrorDialog('Erreur lors de l\'analyse de l\'image: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          'Error',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.inter(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: GoogleFonts.inter(
                color: const Color(0xFF6A0DAD),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startWorkout() {
    if (_analysisResult == null) {
      _showErrorDialog('Please take a picture first to get exercise suggestions');
      return;
    }

    // Get the captured image path
    final imagePath = _cameraController?.value.isInitialized == true 
        ? 'camera_capture_${DateTime.now().millisecondsSinceEpoch}.jpg'
        : '';

    Navigator.of(context).pop(); // Close camera widget
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExerciseSuggestionPage(
          analysis: _analysisResult!,
          imagePath: imagePath,
          duration: _selectedDuration * 60, // Convert to seconds
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Color(0xFF121212), // Neutral Dark
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Text(
                  'Snap Your Space',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Camera Preview or Analysis Result
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _buildContent(),
              ),
            ),
          ),
          
          // Bottom Section
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                if (_analysisResult != null) ...[
                  // Analysis Result
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _isUsingMockData ? Colors.orange : const Color(0xFF6A0DAD),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isUsingMockData ? 'Mock Analysis (API Offline)' : 'AI Analysis Complete',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: _isUsingMockData ? Colors.orange : Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Found ${_analysisResult!.detectedObjects.length} objects and ${_analysisResult!.exerciseSuggestions.length} exercise suggestions',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: const Color(0xFF9E9E9E),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Show detected objects
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _analysisResult!.detectedObjects.take(3).map((object) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6A0DAD).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                object,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF6A0DAD),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Duration Selection
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select workout duration:',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            // 1 Minute Button
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedDuration = 1;
                                  });
                                },
                                child: Container(
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: _selectedDuration == 1 
                                        ? const Color(0xFF6A0DAD) // Primary Accent when selected
                                        : const Color(0xFF2A2A2A), // Dark when not selected
                                    borderRadius: BorderRadius.circular(12),
                                    border: _selectedDuration == 1 
                                        ? Border.all(color: const Color(0xFF6A0DAD), width: 1)
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '1 Min',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(width: 12),
                            
                            // 3 Minutes Button
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedDuration = 3;
                                  });
                                },
                                child: Container(
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: _selectedDuration == 3 
                                        ? const Color(0xFFFFC107) // Secondary Accent when selected
                                        : const Color(0xFF2A2A2A), // Dark when not selected
                                    borderRadius: BorderRadius.circular(12),
                                    border: _selectedDuration == 3 
                                        ? Border.all(color: const Color(0xFFFFC107), width: 1)
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '3 Mins',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Action Buttons
                Row(
                  children: [
                    if (_analysisResult == null) ...[
                      // Take Picture Button
                      Expanded(
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6A0DAD), // Primary Accent
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: _isAnalyzing ? null : _takePicture,
                              child: Center(
                                child: _isAnalyzing
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        'Prendre une photo',
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
                      const SizedBox(width: 12),
                      // Gallery Button
                      Expanded(
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2A2A), // Secondary color
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF6A0DAD),
                              width: 1,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: _isAnalyzing ? null : _selectImageFromGallery,
                              child: Center(
                                child: _isAnalyzing
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.photo_library,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Galerie',
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
                    ] else ...[
                      // Start Workout Button
                      Expanded(
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6A0DAD), // Primary Accent
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: _startWorkout,
                              child: Center(
                                child: Text(
                                  'Start Workout',
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
                      const SizedBox(width: 12),
                      // Retake Button
                      Container(
                        height: 56,
                        width: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              setState(() {
                                _analysisResult = null;
                              });
                            },
                            child: const Icon(
                              Icons.refresh,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isAnalyzing) {
      return Container(
        color: const Color(0xFF1E1E1E),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Color(0xFF6A0DAD),
                strokeWidth: 3,
              ),
              SizedBox(height: 16),
              Text(
                'Analyzing your space...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_analysisResult != null) {
      return Container(
        color: const Color(0xFF1E1E1E),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle,
                color: Color(0xFF6A0DAD),
                size: 64,
              ),
              SizedBox(height: 16),
              Text(
                'Analysis Complete!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (kIsWeb) {
      // Sur le web, afficher un placeholder pour la caméra
      return Container(
        color: const Color(0xFF1E1E1E),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.camera_alt,
                size: 80,
                color: Color(0xFF6A0DAD),
              ),
              SizedBox(height: 16),
              Text(
                'Caméra non disponible sur le web',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Utilisez les boutons ci-dessous pour sélectionner une image',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized || CameraService.cameraController == null) {
      return Container(
        color: const Color(0xFF1E1E1E),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Color(0xFF6A0DAD),
                strokeWidth: 3,
              ),
              SizedBox(height: 16),
              Text(
                'Initialisation de la caméra...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return CameraPreview(CameraService.cameraController!);
  }
}
