import 'dart:ui' as ui;
import 'dart:typed_data' show Uint8List;
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PoseDetectionService {
  PoseDetector? _poseDetector;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final options = PoseDetectorOptions(
        mode: PoseDetectionMode.stream,
        model: PoseDetectionModel.base,
      );

      _poseDetector = PoseDetector(options: options);
      _isInitialized = true;
      print('Pose Detection: Initialized successfully');
    } catch (e) {
      print('Pose Detection: Initialization failed - $e');
      _isInitialized = false;
    }
  }

  Future<List<Pose>> detectPoses(CameraImage image, CameraDescription camera) async {
    if (!_isInitialized || _poseDetector == null) {
      await initialize();
      if (!_isInitialized || _poseDetector == null) {
        print('Pose Detection: Still not initialized');
        return [];
      }
    }

    try {
      // Convert image
      final inputImage = InputImage.fromBytes(
        bytes: _concatenatePlanes(image.planes),
        metadata: InputImageMetadata(
          size: ui.Size(image.width.toDouble(), image.height.toDouble()),
          rotation: _getRotation(camera.sensorOrientation),
          format: InputImageFormat.bgra8888,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );

      // Process image
      final poses = await _poseDetector!.processImage(inputImage);
      
      if (poses.isNotEmpty) {
        // Check if we can detect the nose (basic validation)
        final nose = poses.first.landmarks[PoseLandmarkType.nose];
        if (nose != null) {
          print('Pose Detection: Person detected with nose at (${nose.x}, ${nose.y})');
          return poses;
        } else {
          print('Pose Detection: Person detected but no nose landmark');
          return [];
        }
      } else {
        print('Pose Detection: No person detected');
        return [];
      }
    } catch (e) {
      print('Pose Detection Error: $e');
      return [];
    }
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    int totalLength = 0;
    for (Plane plane in planes) {
      totalLength += plane.bytes.length;
    }
    
    final allBytes = Uint8List(totalLength);
    int offset = 0;
    
    for (Plane plane in planes) {
      allBytes.setRange(offset, offset + plane.bytes.length, plane.bytes);
      offset += plane.bytes.length;
    }
    
    return allBytes;
  }

  InputImageRotation _getRotation(int degrees) {
    switch (degrees) {
      case 0:
        return InputImageRotation.rotation0deg;
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  void dispose() {
    if (_isInitialized && _poseDetector != null) {
      _poseDetector!.close();
      _poseDetector = null;
      _isInitialized = false;
      print('Pose Detection: Disposed');
    }
  }
}