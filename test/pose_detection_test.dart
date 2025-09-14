import 'package:flutter_test/flutter_test.dart';
import 'package:mygym/services/gesture_recognition_service.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

void main() {
  group('Gesture Recognition Service Tests', () {
    late GestureRecognitionService gestureService;

    setUp(() {
      gestureService = GestureRecognitionService();
    });

    test('should initialize with default values', () {
      expect(gestureService.bicepCurlCount, 0);
      expect(gestureService.currentExercise, 'Ready for workout');
    });

    test('should reset count correctly', () {
      // Simulate some counts
      gestureService.resetCount();
      expect(gestureService.bicepCurlCount, 0);
    });

    test('should detect no pose when empty list provided', () {
      final result = gestureService.detectGesture([]);
      expect(result, 'No pose detected');
    });
  });
}
