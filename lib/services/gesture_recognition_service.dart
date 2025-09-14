import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:math' as math;
import 'dart:ui';

/// Service for recognizing specific workout gestures from pose data
class GestureRecognitionService {
  // Thresholds for gesture detection
  static const double _angleThreshold = 30.0; // degrees
  static const double _confidenceThreshold = 0.5;
  
  // Exercise states
  String _currentExercise = 'Ready for workout';
  int _bicepCurlCount = 0;
  bool _isInDownPosition = false;
  bool _isInUpPosition = false;

  /// Detect gestures from pose landmarks
  String detectGesture(List<Pose> poses) {
    if (poses.isEmpty) {
      return 'No pose detected';
    }

    // Get the first pose (most confident)
    final pose = poses.first;
    
    // Detect bicep curl
    final bicepCurlResult = _detectBicepCurl(pose);
    if (bicepCurlResult.isNotEmpty) {
      return bicepCurlResult;
    }

    // Detect other exercises can be added here
    // final squatResult = _detectSquat(pose);
    // final pushUpResult = _detectPushUp(pose);

    return 'Ready for workout';
  }

  /// Detect bicep curl exercise
  String _detectBicepCurl(Pose pose) {
    // Get required landmarks
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];

    // Check if we have valid landmarks
    if (leftShoulder == null || leftElbow == null || leftWrist == null ||
        rightShoulder == null || rightElbow == null || rightWrist == null) {
      return 'Position yourself in front of the camera';
    }

    // Calculate angles for both arms
    final leftAngle = _calculateAngle(leftShoulder, leftElbow, leftWrist);
    final rightAngle = _calculateAngle(rightShoulder, rightElbow, rightWrist);

    // Check confidence levels
    if (leftElbow.likelihood < _confidenceThreshold || 
        rightElbow.likelihood < _confidenceThreshold) {
      return 'Keep your arms visible to the camera';
    }

    // Detect bicep curl movement
    if (leftAngle < 45 && rightAngle < 45) {
      // Down position
      if (!_isInDownPosition) {
        _isInDownPosition = true;
        _isInUpPosition = false;
      }
    } else if (leftAngle > 135 && rightAngle > 135) {
      // Up position
      if (_isInDownPosition && !_isInUpPosition) {
        _isInUpPosition = true;
        _isInDownPosition = false;
        _bicepCurlCount++;
        return 'Bicep Curl Detected! Count: $_bicepCurlCount';
      }
    }

    // Provide feedback based on current position
    if (leftAngle < 45 && rightAngle < 45) {
      return 'Great! Now curl up your arms';
    } else if (leftAngle > 135 && rightAngle > 135) {
      return 'Perfect! Now lower your arms slowly';
    } else {
      return 'Bicep Curl in progress...';
    }
  }

  /// Calculate angle between three points
  double _calculateAngle(PoseLandmark point1, PoseLandmark point2, PoseLandmark point3) {
    // Vector from point2 to point1
    final vector1 = Offset(point1.x - point2.x, point1.y - point2.y);
    
    // Vector from point2 to point3
    final vector2 = Offset(point3.x - point2.x, point3.y - point2.y);
    
    // Calculate dot product
    final dotProduct = vector1.dx * vector2.dx + vector1.dy * vector2.dy;
    
    // Calculate magnitudes
    final magnitude1 = math.sqrt(vector1.dx * vector1.dx + vector1.dy * vector1.dy);
    final magnitude2 = math.sqrt(vector2.dx * vector2.dx + vector2.dy * vector2.dy);
    
    // Calculate angle in radians
    final cosAngle = dotProduct / (magnitude1 * magnitude2);
    final angleRadians = math.acos(cosAngle.clamp(-1.0, 1.0));
    
    // Convert to degrees
    return angleRadians * 180 / math.pi;
  }

  /// Get current exercise count
  int get bicepCurlCount => _bicepCurlCount;

  /// Reset exercise count
  void resetCount() {
    _bicepCurlCount = 0;
    _isInDownPosition = false;
    _isInUpPosition = false;
  }

  /// Get current exercise state
  String get currentExercise => _currentExercise;
}
