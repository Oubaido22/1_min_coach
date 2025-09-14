import 'package:permission_handler/permission_handler.dart';

/// Service to handle camera permissions for pose detection
class PermissionService {
  /// Check if camera permission is granted
  static Future<bool> isCameraPermissionGranted() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  /// Request camera permission
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Check and request camera permission if needed
  /// Returns true if permission is granted, false otherwise
  static Future<bool> ensureCameraPermission() async {
    // First check if permission is already granted
    if (await isCameraPermissionGranted()) {
      return true;
    }

    // Request permission if not granted
    return await requestCameraPermission();
  }

  /// Check if permission is permanently denied
  static Future<bool> isPermissionPermanentlyDenied() async {
    final status = await Permission.camera.status;
    return status.isPermanentlyDenied;
  }

  /// Open app settings if permission is permanently denied
  static Future<void> openAppSettings() async {
    await openAppSettings();
  }
}
