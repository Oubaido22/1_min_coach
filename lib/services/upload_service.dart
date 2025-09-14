import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

/// Service pour gérer l'upload de fichiers vers Firebase Storage
class UploadService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload une image vers Firebase Storage
  /// Gère automatiquement les différences entre web et mobile
  static Future<String> uploadImage({
    required String path,
    required dynamic imageSource, // XFile ou File
    Map<String, String>? metadata,
  }) async {
    try {
      print('Uploading image to path: $path');
      Reference ref = _storage.ref().child(path);

      UploadTask uploadTask;
      if (kIsWeb) {
        // Sur le web, on doit utiliser putData avec les bytes de l'image
        if (imageSource is XFile) {
          final bytes = await imageSource.readAsBytes();
          uploadTask = ref.putData(
            bytes,
            SettableMetadata(
              contentType: 'image/jpeg',
              customMetadata: metadata,
            ),
          );
        } else {
          throw 'Invalid image source for web upload';
        }
      } else {
        // Sur mobile, on peut utiliser putFile
        if (imageSource is File) {
          uploadTask = ref.putFile(
            imageSource,
            SettableMetadata(
              contentType: 'image/jpeg',
              customMetadata: metadata,
            ),
          );
        } else if (imageSource is XFile) {
          uploadTask = ref.putFile(
            File(imageSource.path),
            SettableMetadata(
              contentType: 'image/jpeg',
              customMetadata: metadata,
            ),
          );
        } else {
          throw 'Invalid image source for mobile upload';
        }
      }

      // Attendre la fin de l'upload
      final snapshot = await uploadTask;
      
      // Récupérer l'URL de téléchargement
      final downloadUrl = await snapshot.ref.getDownloadURL();
      print('Upload successful. Download URL: $downloadUrl');
      
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      print('Error type: ${e.runtimeType}');
      throw 'Failed to upload image: ${e.toString()}';
    }
  }

  /// Supprime un fichier de Firebase Storage
  static Future<void> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
      print('File deleted successfully: $url');
    } catch (e) {
      print('Warning: Failed to delete file: $e');
    }
  }
}
