import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:math' as math;

class WorkoutValidatorService {
  // Track exercise state
  bool _isInUpPosition = false;
  int _repCount = 0;
  double _lastQualityScore = 0.0;

  // Exercise validation result
  class ValidationResult {
    final bool isCorrectForm;
    final String message;
    final int repCount;
    final double quality;

    ValidationResult({
      required this.isCorrectForm,
      required this.message,
      required this.repCount,
      required this.quality,
    });
  }

  ValidationResult validatePushUp(Pose pose) {
    try {
      // Get key landmarks
      final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
      final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
      final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
      final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];
      final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
      final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
      final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
      final rightHip = pose.landmarks[PoseLandmarkType.rightHip];

      if (leftShoulder == null || rightShoulder == null || 
          leftElbow == null || rightElbow == null ||
          leftWrist == null || rightWrist == null ||
          leftHip == null || rightHip == null) {
        return ValidationResult(
          isCorrectForm: false,
          message: "Cannot see all body parts clearly",
          repCount: _repCount,
          quality: 0.0,
        );
      }

      // Calculate angles
      double leftElbowAngle = _calculateAngle(leftShoulder, leftElbow, leftWrist);
      double rightElbowAngle = _calculateAngle(rightShoulder, rightElbow, rightWrist);
      double backAngle = _calculateBackAngle(leftShoulder, leftHip, rightShoulder, rightHip);

      // Average elbow angle
      double elbowAngle = (leftElbowAngle + rightElbowAngle) / 2;

      // Check if back is straight (should be close to 180 degrees)
      bool isBackStraight = (backAngle > 170 && backAngle < 190);

      // Detect push-up positions
      if (elbowAngle > 150) { // Arms straight - up position
        if (!_isInUpPosition) {
          _isInUpPosition = true;
          // Only count rep if coming from down position
          _repCount++;
          print('Push-up rep completed: $_repCount');
        }
      } else if (elbowAngle < 90) { // Down position
        _isInUpPosition = false;
      }

      // Calculate form quality (0-100%)
      double elbowQuality = _calculateElbowQuality(leftElbowAngle, rightElbowAngle);
      double backQuality = isBackStraight ? 1.0 : 0.5;
      _lastQualityScore = (elbowQuality + backQuality) / 2 * 100;

      // Generate feedback message
      String message = "";
      if (!isBackStraight) {
        message += "Keep your back straight. ";
      }
      if (math.abs(leftElbowAngle - rightElbowAngle) > 15) {
        message += "Keep your arms even. ";
      }
      if (message.isEmpty) {
        message = "Good form! ";
      }
      message += "Reps: $_repCount";

      return ValidationResult(
        isCorrectForm: isBackStraight && elbowQuality > 0.7,
        message: message,
        repCount: _repCount,
        quality: _lastQualityScore,
      );

    } catch (e) {
      print('Workout validation error: $e');
      return ValidationResult(
        isCorrectForm: false,
        message: "Error analyzing form",
        repCount: _repCount,
        quality: 0.0,
      );
    }
  }

  ValidationResult validateSquat(Pose pose) {
    try {
      // Get key landmarks
      final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
      final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
      final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
      final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];
      final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
      final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];

      if (leftHip == null || rightHip == null || 
          leftKnee == null || rightKnee == null ||
          leftAnkle == null || rightAnkle == null) {
        return ValidationResult(
          isCorrectForm: false,
          message: "Cannot see legs clearly",
          repCount: _repCount,
          quality: 0.0,
        );
      }

      // Calculate knee angles
      double leftKneeAngle = _calculateAngle(leftHip, leftKnee, leftAnkle);
      double rightKneeAngle = _calculateAngle(rightHip, rightKnee, rightAnkle);
      double kneeAngle = (leftKneeAngle + rightKneeAngle) / 2;

      // Detect squat positions
      if (kneeAngle > 150) { // Standing position
        if (!_isInUpPosition) {
          _isInUpPosition = true;
          _repCount++;
          print('Squat rep completed: $_repCount');
        }
      } else if (kneeAngle < 90) { // Squat position
        _isInUpPosition = false;
      }

      // Calculate form quality
      double kneeQuality = _calculateKneeQuality(leftKneeAngle, rightKneeAngle);
      _lastQualityScore = kneeQuality * 100;

      // Generate feedback
      String message = "";
      if (math.abs(leftKneeAngle - rightKneeAngle) > 15) {
        message += "Keep your knees even. ";
      }
      if (kneeAngle > 100 && !_isInUpPosition) {
        message += "Go lower. ";
      }
      if (message.isEmpty) {
        message = "Good form! ";
      }
      message += "Reps: $_repCount";

      return ValidationResult(
        isCorrectForm: kneeQuality > 0.7,
        message: message,
        repCount: _repCount,
        quality: _lastQualityScore,
      );

    } catch (e) {
      print('Workout validation error: $e');
      return ValidationResult(
        isCorrectForm: false,
        message: "Error analyzing form",
        repCount: _repCount,
        quality: 0.0,
      );
    }
  }

  // Helper methods
  double _calculateAngle(PoseLandmark point1, PoseLandmark point2, PoseLandmark point3) {
    double angle = math.atan2(point3.y - point2.y, point3.x - point2.x) -
                  math.atan2(point1.y - point2.y, point1.x - point2.x);
    angle = angle * 180 / math.pi; // Convert to degrees
    angle = angle.abs(); // Get absolute value
    if (angle > 180) angle = 360 - angle; // Get acute or obtuse angle
    return angle;
  }

  double _calculateBackAngle(
    PoseLandmark leftShoulder, 
    PoseLandmark leftHip,
    PoseLandmark rightShoulder,
    PoseLandmark rightHip
  ) {
    // Calculate midpoints
    double midShoulderX = (leftShoulder.x + rightShoulder.x) / 2;
    double midShoulderY = (leftShoulder.y + rightShoulder.y) / 2;
    double midHipX = (leftHip.x + rightHip.x) / 2;
    double midHipY = (leftHip.y + rightHip.y) / 2;

    // Calculate angle with vertical
    double angle = math.atan2(midShoulderY - midHipY, midShoulderX - midHipX);
    angle = angle * 180 / math.pi; // Convert to degrees
    return angle;
  }

  double _calculateElbowQuality(double leftAngle, double rightAngle) {
    // Perfect form has matching angles
    double angleDifference = (leftAngle - rightAngle).abs();
    return math.max(0, 1 - angleDifference / 90);
  }

  double _calculateKneeQuality(double leftAngle, double rightAngle) {
    // Perfect form has matching angles
    double angleDifference = (leftAngle - rightAngle).abs();
    return math.max(0, 1 - angleDifference / 90);
  }

  void reset() {
    _isInUpPosition = false;
    _repCount = 0;
    _lastQualityScore = 0.0;
  }

  int getRepCount() => _repCount;
  double getQuality() => _lastQualityScore;
}
