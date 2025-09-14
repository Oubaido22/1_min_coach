import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;

class PersonDetectionService {
  static const int _motionThreshold = 15; // Lowered threshold for better sensitivity
  static const int _noMotionTimeout = 3; // Reduced timeout for faster response
  static const int _detectionInterval = 500; // Check every 0.5 seconds for faster detection
  
  Timer? _detectionTimer;
  bool _isPersonDetected = true;
  DateTime? _lastMotionTime;
  Uint8List? _previousFrame;
  int _noMotionCount = 0;
  int _motionCount = 0;
  
  // Callbacks
  Function(bool isPersonDetected)? onPersonDetectionChanged;
  Function()? onPersonLost;
  Function()? onPersonFound;
  
  void startDetection(CameraController cameraController) {
    print('🚀 Starting person detection service...');
    _detectionTimer = Timer.periodic(
      const Duration(milliseconds: _detectionInterval),
      (_) => _detectMotion(cameraController),
    );
    
    // Fallback: Simple timer-based detection for testing
    Timer.periodic(const Duration(seconds: 10), (_) {
      if (_isPersonDetected) {
        print('🔄 Fallback: Simulating person lost for testing...');
        _simulatePersonLost();
      } else {
        print('🔄 Fallback: Simulating person found for testing...');
        _simulatePersonFound();
      }
    });
  }
  
  void _simulatePersonLost() {
    _isPersonDetected = false;
    print('⚠️ Simulated person lost - showing warning');
    onPersonLost?.call();
    onPersonDetectionChanged?.call(false);
  }
  
  void _simulatePersonFound() {
    _isPersonDetected = true;
    print('✅ Simulated person found - hiding warning');
    onPersonFound?.call();
    onPersonDetectionChanged?.call(true);
  }
  
  void stopDetection() {
    _detectionTimer?.cancel();
    _detectionTimer = null;
  }
  
  Future<void> _detectMotion(CameraController cameraController) async {
    try {
      if (!cameraController.value.isInitialized) return;
      
      // Capture current frame
      final XFile image = await cameraController.takePicture();
      final Uint8List currentFrame = await image.readAsBytes();
      
      // Delete the temporary file
      await File(image.path).delete();
      
      if (_previousFrame != null) {
        // Compare frames for motion detection
        final bool hasMotion = _compareFrames(_previousFrame!, currentFrame);
        
        print('🔍 Motion detected: $hasMotion');
        
        if (hasMotion) {
          _motionCount++;
          _noMotionCount = 0;
          _lastMotionTime = DateTime.now();
          
          // Require 2 consecutive motion detections to confirm person presence
          if (_motionCount >= 2 && !_isPersonDetected) {
            _isPersonDetected = true;
            print('✅ Person detected - showing person found');
            onPersonFound?.call();
            onPersonDetectionChanged?.call(true);
          }
        } else {
          _noMotionCount++;
          _motionCount = 0;
          
          // Require 3 consecutive no-motion detections to confirm person absence
          if (_noMotionCount >= 3 && _isPersonDetected) {
            _isPersonDetected = false;
            print('⚠️ Person lost - showing warning');
            onPersonLost?.call();
            onPersonDetectionChanged?.call(false);
          }
        }
      } else {
        // First frame - assume person is present
        _isPersonDetected = true;
        _lastMotionTime = DateTime.now();
      }
      
      _previousFrame = currentFrame;
    } catch (e) {
      print('❌ Error in motion detection: $e');
    }
  }
  
  bool _compareFrames(Uint8List frame1, Uint8List frame2) {
    try {
      // Decode images
      final img.Image? image1 = img.decodeImage(frame1);
      final img.Image? image2 = img.decodeImage(frame2);
      
      if (image1 == null || image2 == null) return false;
      
      // Resize images to smaller size for faster comparison
      final img.Image resized1 = img.copyResize(image1, width: 80, height: 60);
      final img.Image resized2 = img.copyResize(image2, width: 80, height: 60);
      
      // Convert to grayscale
      final img.Image gray1 = img.grayscale(resized1);
      final img.Image gray2 = img.grayscale(resized2);
      
      // Calculate difference with improved algorithm
      int totalDifference = 0;
      int pixelCount = 0;
      int significantChanges = 0;
      
      for (int y = 0; y < gray1.height; y++) {
        for (int x = 0; x < gray1.width; x++) {
          final int pixel1 = gray1.getPixel(x, y).r.toInt();
          final int pixel2 = gray2.getPixel(x, y).r.toInt();
          final int difference = (pixel1 - pixel2).abs();
          
          totalDifference += difference;
          pixelCount++;
          
          // Count significant changes (large pixel differences)
          if (difference > 30) {
            significantChanges++;
          }
        }
      }
      
      final double averageDifference = totalDifference / pixelCount;
      final double changePercentage = (significantChanges / pixelCount) * 100;
      
      // Use both average difference and significant change percentage
      final bool hasMotion = averageDifference > _motionThreshold || changePercentage > 2.0;
      
      print('📊 Motion analysis: avg=${averageDifference.toStringAsFixed(1)}, changes=${changePercentage.toStringAsFixed(1)}%, motion=$hasMotion');
      
      return hasMotion;
    } catch (e) {
      print('❌ Error comparing frames: $e');
      return false;
    }
  }
  
  bool get isPersonDetected => _isPersonDetected;
  
  void dispose() {
    stopDetection();
  }
}
