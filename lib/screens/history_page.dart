import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_page.dart';
import 'profile_page.dart';
import '../services/workout_history_service.dart';
import '../services/workout_service.dart';
import '../models/workout_history.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> with TickerProviderStateMixin {
  int _currentIndex = 1; // History is active
  final WorkoutHistoryService _workoutHistoryService = WorkoutHistoryService();
  final WorkoutService _workoutService = WorkoutService();
  List<WorkoutHistory> _workouts = [];
  List<Map<String, dynamic>> _aiWorkouts = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  late AnimationController _avatarController;
  late Animation<double> _avatarAnimation;

  @override
  void initState() {
    super.initState();
    _avatarController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _avatarAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _avatarController,
      curve: Curves.easeInOut,
    ));
    _avatarController.repeat(reverse: true);
    _loadWorkoutData();
  }

  @override
  void dispose() {
    _avatarController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkoutData() async {
    try {
      // Load regular workout history
      final workouts = await _workoutHistoryService.getUserWorkoutHistory();
      final regularStats = await _workoutHistoryService.getWorkoutStats();
      
      // Load AI-generated workouts
      final aiWorkouts = await _workoutService.getWorkoutHistory();
      final aiStats = await _workoutService.getWorkoutStats();
      
      // Combine stats from both regular and AI workouts
      final combinedStats = _combineStats(regularStats, aiStats, workouts, aiWorkouts);
      
      if (mounted) {
        setState(() {
          _workouts = workouts;
          _aiWorkouts = aiWorkouts;
          _stats = combinedStats;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading workout data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Combine stats from regular and AI workouts
  Map<String, dynamic> _combineStats(
    Map<String, dynamic> regularStats,
    Map<String, dynamic> aiStats,
    List<WorkoutHistory> regularWorkouts,
    List<Map<String, dynamic>> aiWorkouts,
  ) {
    // Calculate total minutes from AI workouts (duration is in seconds)
    int aiTotalMinutes = 0;
    for (final aiWorkout in aiWorkouts) {
      final duration = aiWorkout['duration'] ?? 0;
      aiTotalMinutes += ((duration as int) / 60).round();
    }

    // Combine all workouts for streak calculation
    final allWorkouts = <Map<String, dynamic>>[];
    
    // Add regular workouts
    for (final workout in regularWorkouts) {
      allWorkouts.add({
        'completedAt': workout.completedAt,
        'type': workout.workoutType,
      });
    }
    
    // Add AI workouts
    for (final aiWorkout in aiWorkouts) {
      final completedAt = aiWorkout['completedAt'];
      DateTime date;
      if (completedAt is Timestamp) {
        date = completedAt.toDate();
      } else if (completedAt is String) {
        date = DateTime.parse(completedAt);
      } else {
        date = DateTime.now();
      }
      
      allWorkouts.add({
        'completedAt': date,
        'type': 'AI_Generated',
      });
    }

    // Calculate combined streak
    final combinedStreak = _calculateCombinedStreak(allWorkouts);

    return {
      'totalMinutes': (regularStats['totalMinutes'] ?? 0) + aiTotalMinutes,
      'totalWorkouts': (regularStats['totalWorkouts'] ?? 0) + aiWorkouts.length,
      'currentStreak': combinedStreak,
      'workoutTypes': {
        ...Map<String, int>.from(regularStats['workoutTypes'] ?? {}),
        'AI_Generated': aiWorkouts.length,
      },
      'averageWorkoutDuration': _calculateAverageDuration(
        (regularStats['totalMinutes'] ?? 0) + aiTotalMinutes,
        (regularStats['totalWorkouts'] ?? 0) + aiWorkouts.length,
      ),
    };
  }

  /// Calculate streak from combined workouts
  int _calculateCombinedStreak(List<Map<String, dynamic>> allWorkouts) {
    if (allWorkouts.isEmpty) return 0;

    // Sort by completedAt in descending order
    allWorkouts.sort((a, b) => (b['completedAt'] as DateTime).compareTo(a['completedAt'] as DateTime));

    // Group workouts by date
    final Map<String, List<Map<String, dynamic>>> workoutsByDate = {};
    for (var workout in allWorkouts) {
      final dateKey = _getDateKey(workout['completedAt'] as DateTime);
      workoutsByDate[dateKey] ??= [];
      workoutsByDate[dateKey]!.add(workout);
    }

    // Get sorted dates
    final sortedDates = workoutsByDate.keys.toList()..sort((a, b) => b.compareTo(a));

    int streak = 0;
    final today = DateTime.now();
    final todayKey = _getDateKey(today);

    // Check if user worked out today or yesterday
    bool hasWorkedOutToday = workoutsByDate.containsKey(todayKey);
    bool hasWorkedOutYesterday = workoutsByDate.containsKey(_getDateKey(today.subtract(const Duration(days: 1))));

    // If no workout today and no workout yesterday, streak is 0
    if (!hasWorkedOutToday && !hasWorkedOutYesterday) {
      return 0;
    }

    // Start counting from today or yesterday
    DateTime currentDate = hasWorkedOutToday ? today : today.subtract(const Duration(days: 1));
    
    while (true) {
      final dateKey = _getDateKey(currentDate);
      
      if (workoutsByDate.containsKey(dateKey)) {
        streak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  /// Get date key in YYYY-MM-DD format
  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Calculate average workout duration
  int _calculateAverageDuration(int totalMinutes, int totalWorkouts) {
    return totalWorkouts > 0 ? (totalMinutes / totalWorkouts).round() : 0;
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
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Workout History & Achievements',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const SizedBox(width: 40), // Balance the back button
                      ],
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Animated Avatar with Streak
                    Center(
                      child: AnimatedBuilder(
                        animation: _avatarAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _avatarAnimation.value,
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const RadialGradient(
                                  colors: [
                                    Color(0xFF6A0DAD), // Primary Accent
                                    Color(0xFFFFC107), // Secondary Accent
                                  ],
                                  stops: [0.0, 1.0],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF6A0DAD).withOpacity(0.5),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.local_fire_department,
                                        color: Color(0xFF6A0DAD),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          '${_stats['currentStreak'] ?? 0} Days',
                                          style: GoogleFonts.inter(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "You're on fire!",
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: const Color(0xFF9E9E9E),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  Text(
                                    "Keep it up!",
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: const Color(0xFF9E9E9E),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Workout Summary
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          // Workouts this week
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Workouts this week',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: const Color(0xFF9E9E9E),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2A2A2A),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: _getWeeklyProgress(),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFC107),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_getWeeklyWorkoutCount()}/5 sessions',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF9E9E9E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(width: 20),
                          
                          // Total Minutes
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Total Minutes',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: const Color(0xFF9E9E9E),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${_stats['totalMinutes'] ?? 0}',
                                style: GoogleFonts.inter(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Your Achievements
                    Text(
                      'Your Achievements',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Achievement Icons
                    Row(
                      children: [
                        _buildAchievementIcon(
                          icon: Icons.emoji_events,
                          title: 'First Workout',
                          isUnlocked: (_stats['totalWorkouts'] ?? 0) > 0,
                        ),
                        const SizedBox(width: 16),
                        _buildAchievementIcon(
                          icon: Icons.local_fire_department,
                          title: '7-Day Streak',
                          isUnlocked: (_stats['currentStreak'] ?? 0) >= 7,
                        ),
                        const SizedBox(width: 16),
                        _buildAchievementIcon(
                          icon: Icons.fitness_center,
                          title: '10 Workouts',
                          isUnlocked: (_stats['totalWorkouts'] ?? 0) >= 10,
                        ),
                        const SizedBox(width: 16),
                        _buildAchievementIcon(
                          icon: Icons.lock,
                          title: 'More Coming',
                          isUnlocked: false,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Past Workouts
                    Text(
                      'Past Workouts',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Workout List
                    _buildWorkoutList(),
                    
                    const SizedBox(height: 100), // Space for bottom navigation
                  ],
                ),
              ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF121212),
          border: Border(
            top: BorderSide(
              color: Color(0xFF2A2A2A),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: const Color(0xFF121212),
          selectedItemColor: const Color(0xFF6A0DAD),
          unselectedItemColor: const Color(0xFF9E9E9E),
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
            if (index == 0) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
            } else if (index == 2) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            }
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

  Widget _buildAchievementIcon({
    required IconData icon,
    required String title,
    required bool isUnlocked,
  }) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isUnlocked ? const Color(0xFFFFC107) : const Color(0xFF2A2A2A),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isUnlocked ? Colors.white : const Color(0xFF9E9E9E),
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: isUnlocked ? Colors.white : const Color(0xFF9E9E9E),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildWorkoutList() {
    final totalWorkouts = _workouts.length + _aiWorkouts.length;
    
    if (totalWorkouts == 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              Icons.fitness_center_outlined,
              size: 64,
              color: const Color(0xFF9E9E9E),
            ),
            const SizedBox(height: 16),
            Text(
              'No Workouts Yet',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete your first workout to see it here!',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF9E9E9E),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: totalWorkouts,
      itemBuilder: (context, index) {
        if (index < _workouts.length) {
          // Regular workout
          final workout = _workouts[index];
          return _buildWorkoutCard(workout);
        } else {
          // AI workout
          final aiIndex = index - _workouts.length;
          final aiWorkout = _aiWorkouts[aiIndex];
          return _buildAIWorkoutCard(aiWorkout);
        }
      },
    );
  }

  Widget _buildWorkoutCard(WorkoutHistory workout) {
    final date = workout.completedAt;
    final timeString = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    final dateString = '${date.day}/${date.month}/${date.year}';
    
    // Get workout icon based on type
    IconData workoutIcon = _getWorkoutIcon(workout.workoutType);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF6A0DAD).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              workoutIcon,
              color: const Color(0xFF6A0DAD),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workout.workoutType,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${workout.durationMinutes} Min • $dateString',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF9E9E9E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getWorkoutIcon(String workoutType) {
    if (workoutType.toLowerCase().contains('hiit')) {
      return Icons.flash_on;
    } else if (workoutType.toLowerCase().contains('core')) {
      return Icons.fitness_center;
    } else if (workoutType.toLowerCase().contains('cardio')) {
      return Icons.directions_run;
    } else if (workoutType.toLowerCase().contains('strength')) {
      return Icons.fitness_center;
    } else {
      return Icons.fitness_center;
    }
  }

  double _getWeeklyProgress() {
    final weeklyCount = _getWeeklyWorkoutCount();
    return (weeklyCount / 5).clamp(0.0, 1.0);
  }

  int _getWeeklyWorkoutCount() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    
    int count = 0;
    
    // Count regular workouts
    count += _workouts.where((workout) {
      final workoutDate = workout.completedAt;
      return workoutDate.isAfter(weekStart) && workoutDate.isBefore(weekEnd);
    }).length;
    
    // Count AI workouts
    count += _aiWorkouts.where((aiWorkout) {
      final completedAt = aiWorkout['completedAt'];
      DateTime date;
      if (completedAt is Timestamp) {
        date = completedAt.toDate();
      } else if (completedAt is String) {
        date = DateTime.parse(completedAt);
      } else {
        return false;
      }
      return date.isAfter(weekStart) && date.isBefore(weekEnd);
    }).length;
    
    return count;
  }

  Widget _buildAIWorkoutCard(Map<String, dynamic> aiWorkout) {
    final completedAt = aiWorkout['completedAt'] as Timestamp?;
    final date = completedAt?.toDate() ?? DateTime.now();
    final timeString = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    final dateString = '${date.day}/${date.month}/${date.year}';
    final duration = aiWorkout['duration'] ?? 0;
    final exerciseName = aiWorkout['exerciseName'] ?? 'AI Workout';
    final detectedObjects = List<String>.from(aiWorkout['detectedObjects'] ?? []);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF6A0DAD).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF6A0DAD).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Color(0xFF6A0DAD),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exerciseName,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'AI Generated • $dateString at $timeString',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF9E9E9E),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6A0DAD).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(duration / 60).round()}m',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6A0DAD),
                  ),
                ),
              ),
            ],
          ),
          if (detectedObjects.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Environment:',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF9E9E9E),
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: detectedObjects.take(3).map((object) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    object,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: const Color(0xFF9E9E9E),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}