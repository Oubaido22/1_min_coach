import 'dart:ui' as ui;
import 'dart:typed_data' show Uint8List;
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Service for detecting poses using Google ML Kit
class PoseDetectionService {
  late PoseDetector _poseDetector;
  bool _isInitialized = false;

  /// Initialize the pose detector
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Configure pose detector options
    final options = PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
      model: PoseDetectionModel.accurate,
    );

    _poseDetector = PoseDetector(options: options);
    _isInitialized = true;
  }

  /// Process camera image and detect poses
  Future<List<Pose>> detectPoses(CameraImage cameraImage, CameraDescription camera) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Convert CameraImage to InputImage
      final inputImage = _convertCameraImageToInputImage(cameraImage, camera);
      
      // Process the image for pose detection
      final poses = await _poseDetector.processImage(inputImage);
      return poses;
    } catch (e) {
      print('Error detecting poses: $e');
      return [];
    }
  }

  /// Convert CameraImage to InputImage for ML Kit
  InputImage _convertCameraImageToInputImage(CameraImage cameraImage, CameraDescription camera) {
    // Get image rotation based on camera orientation
    final rotation = _getImageRotation(camera.sensorOrientation);
    
    // Get image format
    final format = InputImageFormatValue.fromRawValue(cameraImage.format.raw);
    
    // Get image size
    final size = ui.Size(cameraImage.width.toDouble(), cameraImage.height.toDouble());
    
    // Get image bytes
    final bytes = _convertYUV420ToImageBytes(cameraImage);
    
    // Create InputImageMetadata
    final metadata = InputImageMetadata(
      size: size,
      rotation: rotation,
      format: format ?? InputImageFormat.nv21,
      bytesPerRow: cameraImage.planes.first.bytesPerRow,
    );

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: metadata,
    );
  }

  /// Convert YUV420 format to image bytes
  Uint8List _convertYUV420ToImageBytes(CameraImage cameraImage) {
    final width = cameraImage.width;
    final height = cameraImage.height;
    
    final yPlane = cameraImage.planes[0];
    final uPlane = cameraImage.planes[1];
    final vPlane = cameraImage.planes[2];
    
    final ySize = yPlane.bytesPerRow * height;
    final uSize = uPlane.bytesPerRow * (height ~/ 2);
    final vSize = vPlane.bytesPerRow * (height ~/ 2);
    
    final bytes = Uint8List(ySize + uSize + vSize);
    
    // Copy Y plane
    bytes.setRange(0, ySize, yPlane.bytes);
    
    // Copy U plane
    bytes.setRange(ySize, ySize + uSize, uPlane.bytes);
    
    // Copy V plane
    bytes.setRange(ySize + uSize, ySize + uSize + vSize, vPlane.bytes);
    
    return bytes;
  }

  /// Get image rotation based on camera sensor orientation
  InputImageRotation _getImageRotation(int sensorOrientation) {
    switch (sensorOrientation) {
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

  /// Dispose the pose detector
  void dispose() {
    if (_isInitialized) {
      _poseDetector.close();
      _isInitialized = false;
    }
  }
}
