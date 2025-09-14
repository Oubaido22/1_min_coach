import 'dart:math' as math;
import 'dart:ui';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Service for validating workout quality and movement during 1-minute sessions
class WorkoutValidationService {
  // Workout validation thresholds
  static const double _minimumMovementSpeed = 0.5; // pixels per frame
  static const double _minimumRangeOfMotion = 30.0; // degrees
  static const double _maximumRestTime = 3.0; // seconds
  static const int _minimumRepsPerMinute = 8; // minimum reps for effective workout
  
  // Workout state tracking
  List<Pose> _poseHistory = [];
  DateTime? _lastMovementTime;
  DateTime? _workoutStartTime;
  int _validReps = 0;
  int _totalReps = 0;
  double _workoutIntensity = 0.0;
  bool _isCurrentlyMoving = false;
  String _currentExercise = 'bicep_curl';
  
  // Movement tracking
  double _lastElbowAngle = 0.0;
  double _currentElbowAngle = 0.0;
  bool _isInDownPosition = false;
  bool _isInUpPosition = false;
  
  /// Start workout validation
  void startWorkout() {
    _workoutStartTime = DateTime.now();
    _poseHistory.clear();
    _validReps = 0;
    _totalReps = 0;
    _workoutIntensity = 0.0;
    _isCurrentlyMoving = false;
  }
  
  /// Validate workout quality in real-time
  WorkoutValidationResult validateWorkout(List<Pose> poses) {
    if (poses.isEmpty) {
      return WorkoutValidationResult(
        isValid: false,
        message: 'No pose detected. Position yourself in front of the camera.',
        intensity: 0.0,
        quality: 0.0,
      );
    }
    
    final pose = poses.first;
    _poseHistory.add(pose);
    
    // Keep only last 10 poses for performance
    if (_poseHistory.length > 10) {
      _poseHistory.removeAt(0);
    }
    
    // Analyze movement quality
    final movementAnalysis = _analyzeMovement(pose);
    final formAnalysis = _analyzeForm(pose);
    final intensityAnalysis = _analyzeIntensity();
    
    // Calculate overall workout quality
    final overallQuality = (movementAnalysis.quality + formAnalysis.quality + intensityAnalysis.quality) / 3;
    
    // Determine if workout is effective
    final isValid = _isWorkoutEffective(movementAnalysis, formAnalysis, intensityAnalysis);
    
    return WorkoutValidationResult(
      isValid: isValid,
      message: _generateFeedbackMessage(movementAnalysis, formAnalysis, intensityAnalysis),
      intensity: intensityAnalysis.intensity,
      quality: overallQuality,
      reps: _validReps,
      totalReps: _totalReps,
    );
  }
  
  /// Analyze movement quality and detect if user is actually moving
  MovementAnalysis _analyzeMovement(Pose pose) {
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];
    
    if (leftElbow == null || rightElbow == null) {
      return MovementAnalysis(
        isMoving: false,
        speed: 0.0,
        quality: 0.0,
        message: 'Keep your arms visible to the camera',
      );
    }
    
    // Calculate movement speed
    double movementSpeed = 0.0;
    if (_poseHistory.length > 1) {
      final previousPose = _poseHistory[_poseHistory.length - 2];
      final prevLeftElbow = previousPose.landmarks[PoseLandmarkType.leftElbow];
      final prevRightElbow = previousPose.landmarks[PoseLandmarkType.rightElbow];
      
      if (prevLeftElbow != null && prevRightElbow != null) {
        final leftSpeed = _calculateDistance(leftElbow, prevLeftElbow);
        final rightSpeed = _calculateDistance(rightElbow, prevRightElbow);
        movementSpeed = (leftSpeed + rightSpeed) / 2;
      }
    }
    
    // Determine if user is moving
    final isMoving = movementSpeed > _minimumMovementSpeed;
    
    if (isMoving) {
      _lastMovementTime = DateTime.now();
      _isCurrentlyMoving = true;
    } else {
      _isCurrentlyMoving = false;
    }
    
    // Calculate movement quality
    double quality = 0.0;
    String message = '';
    
    if (movementSpeed > _minimumMovementSpeed * 2) {
      quality = 1.0;
      message = 'Great movement! Keep it up!';
    } else if (movementSpeed > _minimumMovementSpeed) {
      quality = 0.7;
      message = 'Good movement, try to move a bit faster';
    } else {
      quality = 0.3;
      message = 'Move your arms more actively for a real workout!';
    }
    
    return MovementAnalysis(
      isMoving: isMoving,
      speed: movementSpeed,
      quality: quality,
      message: message,
    );
  }
  
  /// Analyze exercise form quality
  FormAnalysis _analyzeForm(Pose pose) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    
    if (leftShoulder == null || leftElbow == null || leftWrist == null ||
        rightShoulder == null || rightElbow == null || rightWrist == null) {
      return FormAnalysis(
        quality: 0.0,
        message: 'Position yourself properly in front of the camera',
        rangeOfMotion: 0.0,
      );
    }
    
    // Calculate angles
    final leftAngle = _calculateAngle(leftShoulder, leftElbow, leftWrist);
    final rightAngle = _calculateAngle(rightShoulder, rightElbow, rightWrist);
    
    // Calculate range of motion
    final rangeOfMotion = (leftAngle + rightAngle) / 2;
    
    // Track rep completion
    _trackRepCompletion(leftAngle, rightAngle);
    
    // Calculate form quality
    double quality = 0.0;
    String message = '';
    
    if (leftAngle > 160 && rightAngle > 160) {
      quality = 1.0;
      message = 'Perfect form! Full range of motion';
    } else if (leftAngle > 120 && rightAngle > 120) {
      quality = 0.8;
      message = 'Good form, try to extend your arms more';
    } else if (leftAngle > 90 && rightAngle > 90) {
      quality = 0.6;
      message = 'Decent form, work on full range of motion';
    } else {
      quality = 0.4;
      message = 'Focus on proper form and full range of motion';
    }
    
    return FormAnalysis(
      quality: quality,
      message: message,
      rangeOfMotion: rangeOfMotion,
    );
  }
  
  /// Analyze workout intensity
  IntensityAnalysis _analyzeIntensity() {
    if (_workoutStartTime == null) {
      return IntensityAnalysis(
        intensity: 0.0,
        quality: 0.0,
        message: 'Start your workout!',
      );
    }
    
    final workoutDuration = DateTime.now().difference(_workoutStartTime!).inSeconds;
    final repsPerMinute = _validReps / (workoutDuration / 60.0);
    
    // Calculate intensity based on reps per minute
    double intensity = 0.0;
    if (repsPerMinute >= _minimumRepsPerMinute) {
      intensity = 1.0;
    } else if (repsPerMinute >= _minimumRepsPerMinute * 0.7) {
      intensity = 0.8;
    } else if (repsPerMinute >= _minimumRepsPerMinute * 0.5) {
      intensity = 0.6;
    } else {
      intensity = 0.4;
    }
    
    // Check for rest periods
    double quality = intensity;
    String message = '';
    
    if (_lastMovementTime != null) {
      final timeSinceLastMovement = DateTime.now().difference(_lastMovementTime!).inSeconds;
      if (timeSinceLastMovement > _maximumRestTime) {
        quality *= 0.5;
        message = 'Keep moving! Don\'t rest too long';
      }
    }
    
    if (repsPerMinute >= _minimumRepsPerMinute) {
      message = 'Excellent intensity! You\'re getting a real workout!';
    } else if (repsPerMinute >= _minimumRepsPerMinute * 0.7) {
      message = 'Good intensity, try to maintain this pace';
    } else {
      message = 'Increase your pace for a more effective workout';
    }
    
    return IntensityAnalysis(
      intensity: intensity,
      quality: quality,
      message: message,
    );
  }
  
  /// Track rep completion for bicep curls
  void _trackRepCompletion(double leftAngle, double rightAngle) {
    final avgAngle = (leftAngle + rightAngle) / 2;
    
    if (avgAngle < 45 && !_isInDownPosition) {
      _isInDownPosition = true;
      _isInUpPosition = false;
    } else if (avgAngle > 135 && _isInDownPosition && !_isInUpPosition) {
      _isInUpPosition = true;
      _isInDownPosition = false;
      _validReps++;
      _totalReps++;
    }
  }
  
  /// Calculate distance between two pose landmarks
  double _calculateDistance(PoseLandmark point1, PoseLandmark point2) {
    final dx = point1.x - point2.x;
    final dy = point1.y - point2.y;
    return math.sqrt(dx * dx + dy * dy);
  }
  
  /// Calculate angle between three points
  double _calculateAngle(PoseLandmark point1, PoseLandmark point2, PoseLandmark point3) {
    final vector1 = Offset(point1.x - point2.x, point1.y - point2.y);
    final vector2 = Offset(point3.x - point2.x, point3.y - point2.y);
    
    final dotProduct = vector1.dx * vector2.dx + vector1.dy * vector2.dy;
    final magnitude1 = math.sqrt(vector1.dx * vector1.dx + vector1.dy * vector1.dy);
    final magnitude2 = math.sqrt(vector2.dx * vector2.dx + vector2.dy * vector2.dy);
    
    final cosAngle = dotProduct / (magnitude1 * magnitude2);
    final angleRadians = math.acos(cosAngle.clamp(-1.0, 1.0));
    
    return angleRadians * 180 / math.pi;
  }
  
  /// Check if workout is effective
  bool _isWorkoutEffective(MovementAnalysis movement, FormAnalysis form, IntensityAnalysis intensity) {
    return movement.quality > 0.5 && 
           form.quality > 0.5 && 
           intensity.quality > 0.5 &&
           _isCurrentlyMoving;
  }
  
  /// Generate comprehensive feedback message
  String _generateFeedbackMessage(MovementAnalysis movement, FormAnalysis form, IntensityAnalysis intensity) {
    if (!_isCurrentlyMoving) {
      return 'Start moving! This is a workout, not a rest session!';
    }
    
    if (movement.quality < 0.5) {
      return movement.message;
    }
    
    if (form.quality < 0.5) {
      return form.message;
    }
    
    if (intensity.quality < 0.5) {
      return intensity.message;
    }
    
    return 'Excellent workout! Keep up the great work!';
  }
  
  /// Get workout statistics
  WorkoutStats getWorkoutStats() {
    return WorkoutStats(
      validReps: _validReps,
      totalReps: _totalReps,
      intensity: _workoutIntensity,
      duration: _workoutStartTime != null ? 
        DateTime.now().difference(_workoutStartTime!).inSeconds : 0,
    );
  }
  
  /// Reset workout validation
  void reset() {
    _poseHistory.clear();
    _lastMovementTime = null;
    _workoutStartTime = null;
    _validReps = 0;
    _totalReps = 0;
    _workoutIntensity = 0.0;
    _isCurrentlyMoving = false;
    _isInDownPosition = false;
    _isInUpPosition = false;
  }
}

/// Data classes for workout validation results
class WorkoutValidationResult {
  final bool isValid;
  final String message;
  final double intensity;
  final double quality;
  final int reps;
  final int totalReps;
  
  WorkoutValidationResult({
    required this.isValid,
    required this.message,
    required this.intensity,
    required this.quality,
    this.reps = 0,
    this.totalReps = 0,
  });
}

class MovementAnalysis {
  final bool isMoving;
  final double speed;
  final double quality;
  final String message;
  
  MovementAnalysis({
    required this.isMoving,
    required this.speed,
    required this.quality,
    required this.message,
  });
}

class FormAnalysis {
  final double quality;
  final String message;
  final double rangeOfMotion;
  
  FormAnalysis({
    required this.quality,
    required this.message,
    required this.rangeOfMotion,
  });
}

class IntensityAnalysis {
  final double intensity;
  final double quality;
  final String message;
  
  IntensityAnalysis({
    required this.intensity,
    required this.quality,
    required this.message,
  });
}

class WorkoutStats {
  final int validReps;
  final int totalReps;
  final double intensity;
  final int duration;
  
  WorkoutStats({
    required this.validReps,
    required this.totalReps,
    required this.intensity,
    required this.duration,
  });
}
