import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class MotionDetectionService {
  PoseLandmark? _previousNose;
  int _repCount = 0;
  
  bool isMoving(List<Pose> poses) {
    if (poses.isEmpty) {
      return false;
    }

    try {
      final nose = poses.first.landmarks[PoseLandmarkType.nose];
      
      if (nose == null) {
        return false;
      }

      if (_previousNose == null) {
        _previousNose = nose;
        return false;
      }

      // Calculate movement
      double dx = nose.x - _previousNose!.x;
      double dy = nose.y - _previousNose!.y;
      double movement = dx * dx + dy * dy;

      _previousNose = nose;

      // Count reps based on movement
      if (movement > 10) {
        _repCount++;
        return true;
      }
      
      return false;
    } catch (e) {
      print('Motion detection error: $e');
      return false;
    }
  }

  int getRepCount() => _repCount;

  void reset() {
    _previousNose = null;
    _repCount = 0;
  }
}