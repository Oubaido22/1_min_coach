import 'dart:io';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'image_picker_service.dart';

/// Service pour gérer la caméra et les permissions
class CameraService {
  static CameraController? _cameraController;
  static List<CameraDescription>? _cameras;
  static bool _isInitialized = false;

  /// Vérifie et demande les permissions de caméra
  static Future<bool> checkCameraPermission() async {
    if (kIsWeb) {
      return true; // Sur web, on ne peut pas utiliser la caméra directement
    }
    
    final status = await Permission.camera.status;
    if (status.isGranted) {
      return true;
    }
    
    if (status.isDenied) {
      final result = await Permission.camera.request();
      return result.isGranted;
    }
    
    if (status.isPermanentlyDenied) {
      // L'utilisateur a refusé définitivement, ouvrir les paramètres
      await openAppSettings();
      return false;
    }
    
    return false;
  }

  /// Initialise la caméra
  static Future<CameraController?> initializeCamera() async {
    if (kIsWeb) {
      print('Camera not supported on web');
      return null;
    }

    try {
      // Vérifier les permissions
      final hasPermission = await checkCameraPermission();
      if (!hasPermission) {
        print('Camera permission denied');
        return null;
      }

      // Obtenir les caméras disponibles
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        print('No cameras available');
        return null;
      }

      // Créer le contrôleur de caméra
      _cameraController = CameraController(
        _cameras![0], // Utiliser la première caméra (généralement la caméra arrière)
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      // Initialiser la caméra
      await _cameraController!.initialize();
      _isInitialized = true;
      
      print('Camera initialized successfully');
      return _cameraController;
    } catch (e) {
      print('Error initializing camera: $e');
      _isInitialized = false;
      return null;
    }
  }

  /// Prend une photo
  static Future<XFile?> takePicture() async {
    if (kIsWeb) {
      print('Camera not supported on web, using image picker instead');
      // Sur le web, utiliser image_picker comme fallback
      return await ImagePickerService.takePictureWithCamera();
    }

    if (_cameraController == null || !_isInitialized) {
      print('Camera not initialized');
      return null;
    }

    try {
      if (!_cameraController!.value.isInitialized) {
        print('Camera controller not initialized');
        return null;
      }

      final XFile image = await _cameraController!.takePicture();
      print('Picture taken: ${image.path}');
      return image;
    } catch (e) {
      print('Error taking picture: $e');
      return null;
    }
  }

  /// Libère les ressources de la caméra
  static Future<void> dispose() async {
    if (_cameraController != null) {
      await _cameraController!.dispose();
      _cameraController = null;
      _isInitialized = false;
    }
  }

  /// Obtient le contrôleur de caméra
  static CameraController? get cameraController => _cameraController;

  /// Vérifie si la caméra est initialisée
  static bool get isInitialized => _isInitialized;

  /// Obtient la liste des caméras
  static List<CameraDescription>? get cameras => _cameras;
}
