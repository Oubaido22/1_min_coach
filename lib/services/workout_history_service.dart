import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/workout_history.dart';

class WorkoutHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection name for workout history
  static const String _collectionName = 'workout_history';

  /// Save a completed workout to the history
  Future<void> saveWorkout({
    required int durationMinutes,
    required String workoutType,
    String? notes,
    Map<String, dynamic>? workoutData,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw 'User not authenticated';
      }

      final now = DateTime.now();
      final workoutId = _generateWorkoutId();

      final workout = WorkoutHistory(
        id: workoutId,
        userId: currentUser.uid,
        completedAt: now,
        durationMinutes: durationMinutes,
        workoutType: workoutType,
        notes: notes,
        workoutData: workoutData,
        createdAt: now,
      );

      await _firestore
          .collection(_collectionName)
          .doc(workoutId)
          .set(workout.toMap());

      print('Workout saved successfully: $workoutId');
    } catch (e) {
      print('Error saving workout: $e');
      throw 'Failed to save workout: $e';
    }
  }

  /// Get all workout history for the current user
  Future<List<WorkoutHistory>> getUserWorkoutHistory() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw 'User not authenticated';
      }

      print('Fetching workout history for user: ${currentUser.uid}');
      
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      print('Found ${querySnapshot.docs.length} workout documents');
      
      final workouts = querySnapshot.docs
          .where((doc) {
            final data = doc.data();
            // Only include regular workouts, exclude AI-generated workouts
            return data['type'] != 'AI_Generated';
          })
          .map((doc) {
            print('Workout doc: ${doc.id} - ${doc.data()}');
            return WorkoutHistory.fromMap(doc.data());
          })
          .toList();

      // Sort by completedAt in descending order
      workouts.sort((a, b) => b.completedAt.compareTo(a.completedAt));

      print('Parsed ${workouts.length} workouts');
      return workouts;
    } catch (e) {
      print('Error fetching workout history: $e');
      throw 'Failed to fetch workout history: $e';
    }
  }

  /// Get workout history stream for real-time updates
  Stream<List<WorkoutHistory>> getUserWorkoutHistoryStream() {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw 'User not authenticated';
      }

      return _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: currentUser.uid)
          .orderBy('completedAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .where((doc) {
                final data = doc.data();
                // Only include regular workouts, exclude AI-generated workouts
                return data['type'] != 'AI_Generated';
              })
              .map((doc) => WorkoutHistory.fromMap(doc.data()))
              .toList());
    } catch (e) {
      print('Error creating workout history stream: $e');
      throw 'Failed to create workout history stream: $e';
    }
  }

  /// Calculate total workout minutes for the current user
  Future<int> getTotalWorkoutMinutes() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw 'User not authenticated';
      }

      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      int totalMinutes = 0;
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        totalMinutes += (data['durationMinutes'] ?? 0) as int;
      }

      return totalMinutes;
    } catch (e) {
      print('Error calculating total workout minutes: $e');
      return 0;
    }
  }

  /// Calculate current streak (consecutive days with at least one workout)
  Future<int> getCurrentStreak() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw 'User not authenticated';
      }

      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: currentUser.uid)
          .orderBy('completedAt', descending: true)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return 0;
      }

      final workouts = querySnapshot.docs
          .where((doc) {
            final data = doc.data();
            // Only include regular workouts, exclude AI-generated workouts
            return data['type'] != 'AI_Generated';
          })
          .map((doc) => WorkoutHistory.fromMap(doc.data()))
          .toList();

      return _calculateStreak(workouts);
    } catch (e) {
      print('Error calculating streak: $e');
      return 0;
    }
  }

  /// Calculate streak from a list of workouts
  int _calculateStreak(List<WorkoutHistory> workouts) {
    if (workouts.isEmpty) return 0;

    // Group workouts by date
    final Map<String, List<WorkoutHistory>> workoutsByDate = {};
    for (var workout in workouts) {
      final dateKey = _getDateKey(workout.completedAt);
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

  /// Generate unique workout ID
  String _generateWorkoutId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'workout_${timestamp}_$random';
  }

  /// Get workout statistics
  Future<Map<String, dynamic>> getWorkoutStats() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw 'User not authenticated';
      }

      print('Getting workout stats for user: ${currentUser.uid}');

      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      print('Found ${querySnapshot.docs.length} workout documents for stats');

      final workouts = querySnapshot.docs
          .where((doc) {
            final data = doc.data();
            // Only include regular workouts, exclude AI-generated workouts
            return data['type'] != 'AI_Generated';
          })
          .map((doc) => WorkoutHistory.fromMap(doc.data()))
          .toList();

      int totalMinutes = 0;
      int totalWorkouts = workouts.length;
      Map<String, int> workoutTypes = {};

      for (var workout in workouts) {
        totalMinutes += workout.durationMinutes;
        workoutTypes[workout.workoutType] = (workoutTypes[workout.workoutType] ?? 0) + 1;
        print('Workout: ${workout.workoutType} - ${workout.durationMinutes} minutes');
      }

      final streak = _calculateStreak(workouts);

      final stats = {
        'totalMinutes': totalMinutes,
        'totalWorkouts': totalWorkouts,
        'currentStreak': streak,
        'workoutTypes': workoutTypes,
        'averageWorkoutDuration': totalWorkouts > 0 ? (totalMinutes / totalWorkouts).round() : 0,
      };

      print('Calculated stats: $stats');
      return stats;
    } catch (e) {
      print('Error getting workout stats: $e');
      return {
        'totalMinutes': 0,
        'totalWorkouts': 0,
        'currentStreak': 0,
        'workoutTypes': {},
        'averageWorkoutDuration': 0,
      };
    }
  }

  /// Delete a specific workout
  Future<void> deleteWorkout(String workoutId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw 'User not authenticated';
      }

      // Verify the workout belongs to the current user
      final doc = await _firestore.collection(_collectionName).doc(workoutId).get();
      if (!doc.exists) {
        throw 'Workout not found';
      }

      final data = doc.data()!;
      if (data['userId'] != currentUser.uid) {
        throw 'Unauthorized to delete this workout';
      }

      await _firestore.collection(_collectionName).doc(workoutId).delete();
      print('Workout deleted successfully: $workoutId');
    } catch (e) {
      print('Error deleting workout: $e');
      throw 'Failed to delete workout: $e';
    }
  }
}
