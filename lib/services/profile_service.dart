import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/user_profile.dart';

class ProfileService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // Upload profile picture to Firebase Storage
  Future<String> uploadProfilePicture(String userId, File imageFile) async {
    try {
      // Generate unique filename
      String fileName = '${_uuid.v4()}.jpg';
      String path = 'profile_pictures/$userId/$fileName';
      
      print('Uploading profile picture for user: $userId');
      print('File path: $path');
      print('File size: ${await imageFile.length()} bytes');
      
      // Create reference to the file location
      Reference ref = _storage.ref().child(path);
      
      // Upload the file
      UploadTask uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'userId': userId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );
      
      // Wait for upload to complete
      TaskSnapshot snapshot = await uploadTask;
      
      // Get download URL
      String downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('Profile picture uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Error uploading profile picture: $e');
      print('Error type: ${e.runtimeType}');
      throw 'Failed to upload profile picture: ${e.toString()}';
    }
  }

  // Save complete user profile to Firestore
  Future<void> saveUserProfile(UserProfile profile) async {
    try {
      await _firestore.collection('users').doc(profile.uid).set(profile.toMap());
    } catch (e) {
      throw 'Failed to save user profile: ${e.toString()}';
    }
  }


  // Update user profile
  Future<void> updateUserProfile(String userId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('users').doc(userId).update(updates);
    } catch (e) {
      throw 'Failed to update user profile: ${e.toString()}';
    }
  }

  // Generate unique user token
  String generateUserToken() {
    return _uuid.v4();
  }

  // Get user profile from Firestore
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      print('Fetching user profile for: $userId');
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
      
      if (doc.exists) {
        print('User profile found in Firestore');
        UserProfile profile = UserProfile.fromMap(doc.data() as Map<String, dynamic>);
        print('Profile data: ${profile.toMap()}');
        return profile;
      } else {
        print('No user profile found in Firestore');
        return null;
      }
    } catch (e) {
      print('Error fetching user profile: $e');
      throw 'Failed to fetch user profile: ${e.toString()}';
    }
  }

  // Stream user profile from Firestore
  Stream<UserProfile?> getUserProfileStream(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        return UserProfile.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  // Complete user onboarding with all data
  Future<UserProfile> completeUserOnboarding({
    required String userId,
    required String email,
    required String fullName,
    required double height,
    required double weight,
    required String objective,
    required String experienceLevel,
    required int sessionsPerDay,
    required File profilePicture,
  }) async {
    try {
      // Check authentication state
      final currentUser = FirebaseAuth.instance.currentUser;
      print('Current authenticated user: ${currentUser?.uid}');
      print('Expected user ID: $userId');
      
      if (currentUser == null) {
        throw 'User not authenticated';
      }
      
      if (currentUser.uid != userId) {
        throw 'User ID mismatch';
      }
      
      // Upload profile picture to Firebase Storage
      String profilePictureUrl = await uploadProfilePicture(userId, profilePicture);
      
      // Generate user token
      String userToken = generateUserToken();
      
      // Create user profile
      UserProfile profile = UserProfile(
        uid: userId,
        email: email,
        fullName: fullName,
        height: height,
        weight: weight,
        objective: objective,
        experienceLevel: experienceLevel,
        sessionsPerDay: sessionsPerDay,
        profilePictureUrl: profilePictureUrl,
        userToken: userToken,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );
      
      // Save to Firestore
      await saveUserProfile(profile);
      
      print('User profile created successfully with Firebase Storage image');
      return profile;
    } catch (e) {
      throw 'Failed to complete user onboarding: ${e.toString()}';
    }
  }

  // Delete profile picture from storage
  Future<void> deleteProfilePicture(String userId, String imageUrl) async {
    try {
      // Extract path from URL
      String path = _extractPathFromUrl(imageUrl);
      if (path.isNotEmpty) {
        Reference ref = _storage.ref().child(path);
        await ref.delete();
      }
    } catch (e) {
      // Don't throw error for deletion failures
      print('Warning: Failed to delete profile picture: $e');
    }
  }

  // Extract storage path from download URL
  String _extractPathFromUrl(String url) {
    try {
      Uri uri = Uri.parse(url);
      String path = uri.path;
      // Remove the leading slash and any query parameters
      if (path.startsWith('/')) {
        path = path.substring(1);
      }
      return path;
    } catch (e) {
      return '';
    }
  }

  // Update profile picture
  Future<String> updateProfilePicture(String userId, File newImageFile, String? oldImageUrl) async {
    try {
      // Delete old profile picture if it exists
      if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
        await deleteProfilePicture(userId, oldImageUrl);
      }
      
      // Upload new profile picture
      String newImageUrl = await uploadProfilePicture(userId, newImageFile);
      
      // Update user profile in Firestore
      await updateUserProfile(userId, {
        'profilePictureUrl': newImageUrl,
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
      
      return newImageUrl;
    } catch (e) {
      throw 'Failed to update profile picture: ${e.toString()}';
    }
  }
}
