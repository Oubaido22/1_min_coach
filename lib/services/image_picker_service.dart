import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

/// Service pour gérer la sélection d'images depuis la galerie
class ImagePickerService {
  static final ImagePicker _picker = ImagePicker();

  /// Vérifie et demande les permissions de stockage
  static Future<bool> checkStoragePermission() async {
    if (kIsWeb) {
      return true; // Sur web, les permissions sont gérées différemment
    }
    
    // Pour Android 13+, on utilise les permissions de photos
    if (Platform.isAndroid) {
      final status = await Permission.photos.status;
      if (status.isGranted) {
        return true;
      }
      
      if (status.isDenied) {
        final result = await Permission.photos.request();
        return result.isGranted;
      }
      
      if (status.isPermanentlyDenied) {
        await openAppSettings();
        return false;
      }
    }
    
    return true;
  }

  /// Sélectionne une image depuis la galerie
  static Future<XFile?> pickImageFromGallery() async {
    try {
      // Vérifier les permissions
      final hasPermission = await checkStoragePermission();
      if (!hasPermission) {
        print('Storage permission denied');
        return null;
      }

      // Sélectionner l'image depuis la galerie
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        print('Image selected from gallery: ${image.path}');
      } else {
        print('No image selected');
      }

      return image;
    } catch (e) {
      print('Error picking image from gallery: $e');
      return null;
    }
  }

  /// Prend une photo avec la caméra
  static Future<XFile?> takePictureWithCamera() async {
    try {
      // Vérifier les permissions de caméra
      final hasPermission = await Permission.camera.request().isGranted;
      if (!hasPermission) {
        print('Camera permission denied');
        return null;
      }

      // Prendre une photo
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        print('Picture taken with camera: ${image.path}');
      } else {
        print('No picture taken');
      }

      return image;
    } catch (e) {
      print('Error taking picture with camera: $e');
      return null;
    }
  }

  /// Sélectionne une image (galerie ou caméra)
  static Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      if (source == ImageSource.camera) {
        return await takePictureWithCamera();
      } else {
        return await pickImageFromGallery();
      }
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }
}
