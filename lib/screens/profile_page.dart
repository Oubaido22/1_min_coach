import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../services/workout_history_service.dart';
import '../services/workout_service.dart';
import '../models/user_profile.dart';
import '../models/workout_history.dart';
import '../widgets/auth_wrapper.dart';
import 'home_page.dart';
import 'history_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _currentIndex = 2; // Profile is active
  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();
  final WorkoutHistoryService _workoutHistoryService = WorkoutHistoryService();
  final WorkoutService _workoutService = WorkoutService();
  User? _currentUser;
  UserProfile? _userProfile;
  Map<String, dynamic> _workoutStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentUser = _authService.currentUser;
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    if (_currentUser != null) {
      try {
        setState(() {
          _isLoading = true;
        });
        
        // Load user profile
        UserProfile? profile = await _profileService.getUserProfile(_currentUser!.uid);
        
        // Load workout statistics
        final regularStats = await _workoutHistoryService.getWorkoutStats();
        final aiWorkouts = await _workoutService.getWorkoutHistory();
        final aiStats = await _workoutService.getWorkoutStats();
        
        // Combine stats from both regular and AI workouts
        final combinedStats = _combineStats(regularStats, aiStats, aiWorkouts);
        
        if (mounted) {
          setState(() {
            _userProfile = profile;
            _workoutStats = combinedStats;
            _isLoading = false;
          });
        }
      } catch (e) {
        print('Error loading user profile: $e');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Combine stats from regular and AI workouts
  Map<String, dynamic> _combineStats(
    Map<String, dynamic> regularStats,
    Map<String, dynamic> aiStats,
    List<Map<String, dynamic>> aiWorkouts,
  ) {
    // Calculate total minutes from AI workouts (duration is in seconds)
    int aiTotalMinutes = 0;
    for (final aiWorkout in aiWorkouts) {
      final duration = aiWorkout['duration'] ?? 0;
      aiTotalMinutes += ((duration as int) / 60).round();
    }

    return {
      'totalMinutes': (regularStats['totalMinutes'] ?? 0) + aiTotalMinutes,
      'totalWorkouts': (regularStats['totalWorkouts'] ?? 0) + aiWorkouts.length,
      'currentStreak': regularStats['currentStreak'] ?? 0,
      'workoutTypes': {
        ...Map<String, int>.from(regularStats['workoutTypes'] ?? {}),
        'AI_Generated': aiWorkouts.length,
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Neutral Dark
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6A0DAD)),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Profile',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: _loadUserProfile,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.refresh,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Profile Picture and Info
                    Center(
                      child: Column(
                        children: [
                          // Profile Picture
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFC107), // Secondary Accent
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF6A0DAD), // Primary Accent
                                width: 3,
                              ),
                            ),
                            child: _userProfile?.profilePictureUrl != null
                                ? ClipOval(
                                    child: Image.network(
                                      _userProfile!.profilePictureUrl!,
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(
                                          Icons.person,
                                          color: Colors.white,
                                          size: 60,
                                        );
                                      },
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return const Center(
                                          child: CircularProgressIndicator(
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            strokeWidth: 2,
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                : const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 60,
                                  ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Name
                          Text(
                            _userProfile?.fullName ?? _currentUser?.displayName ?? 'User',
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          
                          const SizedBox(height: 4),
                          
                          // Email
                          Text(
                            _userProfile?.email ?? _currentUser?.email ?? '',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: const Color(0xFF9E9E9E), // Light gray
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Achievements Section
                    Text(
                      'Achievements',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Achievements Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          // Total Workouts
                          Expanded(
                            child: Column(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFC107), // Secondary Accent
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.fitness_center,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${_workoutStats['totalWorkouts'] ?? 0}',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Workouts',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: const Color(0xFF9E9E9E), // Light gray
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Current Streak
                          Expanded(
                            child: Column(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFC107), // Secondary Accent
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.local_fire_department,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${_workoutStats['currentStreak'] ?? 0}',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Day Streak',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: const Color(0xFF9E9E9E), // Light gray
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Total Minutes
                          Expanded(
                            child: Column(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFC107), // Secondary Accent
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.timer,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${_workoutStats['totalMinutes'] ?? 0}',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Minutes',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: const Color(0xFF9E9E9E), // Light gray
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Editable Details
                    _buildEditableCard(
                      'Height', 
                      _userProfile?.height != null ? '${_userProfile!.height!.toStringAsFixed(0)} cm' : 'Not set', 
                      Icons.height
                    ),
                    const SizedBox(height: 12),
                    _buildEditableCard(
                      'Weight', 
                      _userProfile?.weight != null ? '${_userProfile!.weight!.toStringAsFixed(0)} kg' : 'Not set', 
                      Icons.monitor_weight
                    ),
                    const SizedBox(height: 12),
                    _buildEditableCard(
                      'Fitness Goal', 
                      _userProfile?.objective ?? 'Not set', 
                      Icons.flag
                    ),
                    const SizedBox(height: 12),
                    _buildEditableCard(
                      'Experience Level', 
                      _userProfile?.experienceLevel ?? 'Not set', 
                      Icons.star
                    ),
                    const SizedBox(height: 12),
                    _buildEditableCard(
                      'Sessions Per Day', 
                      _userProfile?.sessionsPerDay != null ? '${_userProfile!.sessionsPerDay} sessions' : 'Not set', 
                      Icons.fitness_center
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Settings
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Settings',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.chevron_right,
                            color: Color(0xFF9E9E9E), // Light gray
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Log Out
                    GestureDetector(
                      onTap: _signOut,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.logout,
                              color: Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Log Out',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 100), // Space for bottom navigation
                  ],
                ),
              ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF121212), // Neutral Dark
          border: Border(
            top: BorderSide(
              color: Color(0xFF2A2A2A),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: const Color(0xFF121212), // Neutral Dark
          selectedItemColor: const Color(0xFF6A0DAD), // Primary Accent
          unselectedItemColor: const Color(0xFF9E9E9E), // Light gray
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
            if (index == 0) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
            } else if (index == 1) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HistoryPage()),
              );
            }
            // Profile (index 2) is already active
          },
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: Icon(
                _currentIndex == 0 ? Icons.home : Icons.home_outlined,
                size: 24,
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.history,
                size: 24,
              ),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                _currentIndex == 2 ? Icons.person : Icons.person_outline,
                size: 24,
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    // Show confirmation dialog
    bool? shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          'Sign Out',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: GoogleFonts.inter(
            color: Colors.white,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: const Color(0xFF9E9E9E),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Sign Out',
              style: GoogleFonts.inter(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldSignOut == true) {
      try {
        await _authService.signOut();
        // Small delay to ensure sign-out completes
        await Future.delayed(const Duration(milliseconds: 100));
        // Navigate back to AuthWrapper (root) which will show welcome page
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const AuthWrapper(),
            ),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error signing out: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildEditableCard(String label, String value, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF9E9E9E), // Light gray
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF9E9E9E), // Light gray
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.edit,
            color: Color(0xFF9E9E9E), // Light gray
            size: 20,
          ),
        ],
      ),
    );
  }
}