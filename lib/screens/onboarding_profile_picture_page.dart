import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/profile_service.dart';
import '../models/user_profile.dart';
import 'home_page.dart';

class OnboardingProfilePicturePage extends StatefulWidget {
  final String fullName;
  final String email;
  final double height;
  final double weight;
  final String objective; // fitness goal (Lose Weight, Build Muscle, etc.)
  final String experienceLevel; // experience level (Beginner, Intermediate, Advanced)
  final int sessionsPerDay; // number of workout sessions per day

  const OnboardingProfilePicturePage({
    super.key,
    required this.fullName,
    required this.email,
    required this.height,
    required this.weight,
    required this.objective,
    required this.experienceLevel,
    required this.sessionsPerDay,
  });

  @override
  State<OnboardingProfilePicturePage> createState() => _OnboardingProfilePicturePageState();
}

class _OnboardingProfilePicturePageState extends State<OnboardingProfilePicturePage> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  final ProfileService _profileService = ProfileService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFF121212), // Neutral Dark
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Progress indicator
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6A0DAD), // Primary Accent
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6A0DAD), // Primary Accent
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6A0DAD), // Primary Accent
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6A0DAD), // Primary Accent
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 40),
                
                // Title
                Text(
                  'Add Your Profile Picture',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                // Subtitle
                Text(
                  'Let\'s add a profile picture to personalize your experience',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: const Color(0xFF9E9E9E), // Light gray
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 60),
                
                // Profile picture section
                Center(
                  child: GestureDetector(
                    onTap: _showImageSourceDialog,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: const Color(0xFF6A0DAD), // Primary Accent
                          width: 3,
                        ),
                      ),
                      child: _selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(100),
                              child: Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                                width: 200,
                                height: 200,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.camera_alt,
                                  size: 60,
                                  color: const Color(0xFF6A0DAD), // Primary Accent
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Tap to add photo',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: const Color(0xFF9E9E9E), // Light gray
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Image source buttons
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _pickImage(ImageSource.camera),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.camera_alt,
                                  color: Color(0xFF6A0DAD), // Primary Accent
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Take Photo',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    Expanded(
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _pickImage(ImageSource.gallery),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.photo_library,
                                  color: Color(0xFF6A0DAD), // Primary Accent
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Choose from Gallery',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 40),
                
                // Continue button
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _selectedImage != null 
                        ? const Color(0xFF6A0DAD) // Primary Accent
                        : const Color(0xFF2A2A2A), // Disabled color
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _selectedImage != null ? _completeOnboarding : null,
                      child: Center(
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                'Complete Setup',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _selectedImage != null 
                                      ? Colors.white 
                                      : const Color(0xFF9E9E9E), // Light gray
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Image Source',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.camera_alt,
                            color: Color(0xFF6A0DAD),
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Camera',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.photo_library,
                            color: Color(0xFF6A0DAD),
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Gallery',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showErrorDialog('Failed to pick image: ${e.toString()}');
    }
  }

  Future<void> _completeOnboarding() async {
    if (_selectedImage == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw 'User not authenticated';
      }

      // Complete user onboarding with all data
      UserProfile profile = await _profileService.completeUserOnboarding(
        userId: currentUser.uid,
        email: widget.email,
        fullName: widget.fullName,
        height: widget.height,
        weight: widget.weight,
        objective: widget.objective,
        experienceLevel: widget.experienceLevel,
        sessionsPerDay: widget.sessionsPerDay,
        profilePicture: _selectedImage!,
      );

      print('User onboarding completed successfully!');
      print('User Token: ${profile.userToken}');
      print('Profile Picture URL: ${profile.profilePictureUrl}');
      print('Objective (Fitness Goal): ${profile.objective}');
      print('Experience Level: ${profile.experienceLevel}');
      print('Sessions Per Day: ${profile.sessionsPerDay}');
      
      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile setup completed successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Navigate to home page after a short delay
        await Future.delayed(Duration(seconds: 1));
        
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const HomePage(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      String errorMessage = 'Failed to complete setup: ${e.toString()}';
      
      // Provide more user-friendly error messages
      if (e.toString().contains('firebase_storage')) {
        errorMessage = 'Failed to upload profile picture. Please check your internet connection and try again.';
      } else if (e.toString().contains('permission')) {
        errorMessage = 'Permission denied. Please check your internet connection and try again.';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Network error. Please check your internet connection and try again.';
      }
      
      _showErrorDialog(errorMessage);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          'Error',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.inter(
            color: Colors.white,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: GoogleFonts.inter(
                color: const Color(0xFF6A0DAD),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
