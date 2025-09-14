import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/exercise_analysis.dart';

class WorkoutService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Save completed workout to Firestore
  Future<void> saveCompletedWorkout({
    required String exerciseName,
    required String instructions,
    required int duration, // in seconds
    required List<String> detectedObjects,
    required String? imagePath,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw 'User not authenticated';
      }

      final workoutData = {
        'userId': user.uid,
        'exerciseName': exerciseName,
        'instructions': instructions,
        'duration': duration,
        'detectedObjects': detectedObjects,
        'imagePath': imagePath,
        'completedAt': FieldValue.serverTimestamp(),
        'type': 'AI_Generated', // To distinguish from other workout types
      };

      print('💾 Saving completed workout to Firestore...');
      print('👤 User: ${user.uid}');
      print('💪 Exercise: $exerciseName');
      print('⏱️ Duration: ${duration}s');

      await _firestore
          .collection('workout_history')
          .add(workoutData);

      print('✅ Workout saved to Firestore successfully');
    } catch (e) {
      print('❌ Error saving workout to Firestore: $e');
      throw 'Failed to save workout: $e';
    }
  }

  /// Get workout history for the current user
  Future<List<Map<String, dynamic>>> getWorkoutHistory() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return [];
      }

      print('📚 Fetching workout history for user: ${user.uid}');

      final querySnapshot = await _firestore
          .collection('workout_history')
          .where('userId', isEqualTo: user.uid)
          .orderBy('completedAt', descending: true)
          .get();

      final workouts = querySnapshot.docs
          .where((doc) {
            final data = doc.data();
            // Only include AI-generated workouts
            return data['type'] == 'AI_Generated';
          })
          .map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              ...data,
            };
          })
          .toList();

      print('📊 Found ${workouts.length} workout records');
      return workouts;
    } catch (e) {
      print('❌ Error fetching workout history: $e');
      return [];
    }
  }

  /// Get workout statistics for the current user
  Future<Map<String, dynamic>> getWorkoutStats() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {
          'totalMinutes': 0,
          'totalWorkouts': 0,
          'currentStreak': 0,
          'workoutTypes': {},
          'averageWorkoutDuration': 0,
        };
      }

      print('📈 Calculating workout stats for user: ${user.uid}');

      final querySnapshot = await _firestore
          .collection('workout_history')
          .where('userId', isEqualTo: user.uid)
          .get();

      final workouts = querySnapshot.docs
          .where((doc) {
            final data = doc.data();
            // Only include AI-generated workouts
            return data['type'] == 'AI_Generated';
          })
          .map((doc) => doc.data())
          .toList();

      // Calculate statistics
      int totalMinutes = 0;
      int totalWorkouts = workouts.length;
      Map<String, int> workoutTypes = {};

      for (final workout in workouts) {
        final duration = workout['duration'] ?? 0;
        totalMinutes += ((duration as int) / 60).round();
        
        final type = workout['type'] ?? 'Unknown';
        workoutTypes[type] = (workoutTypes[type] ?? 0) + 1;
      }

      final averageWorkoutDuration = totalWorkouts > 0 
          ? (totalMinutes / totalWorkouts).round() 
          : 0;

      // Calculate current streak (simplified - consecutive days with workouts)
      int currentStreak = 0;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      for (int i = 0; i < 30; i++) { // Check last 30 days
        final checkDate = today.subtract(Duration(days: i));
        final hasWorkoutOnDate = workouts.any((workout) {
          final completedAt = workout['completedAt'] as Timestamp?;
          if (completedAt == null) return false;
          final workoutDate = DateTime(
            completedAt.toDate().year,
            completedAt.toDate().month,
            completedAt.toDate().day,
          );
          return workoutDate.isAtSameMomentAs(checkDate);
        });
        
        if (hasWorkoutOnDate) {
          currentStreak++;
        } else if (i > 0) { // Don't break streak on first day if no workout
          break;
        }
      }

      final stats = {
        'totalMinutes': totalMinutes,
        'totalWorkouts': totalWorkouts,
        'currentStreak': currentStreak,
        'workoutTypes': workoutTypes,
        'averageWorkoutDuration': averageWorkoutDuration,
      };

      print('📊 Calculated stats: $stats');
      return stats;
    } catch (e) {
      print('❌ Error calculating workout stats: $e');
      return {
        'totalMinutes': 0,
        'totalWorkouts': 0,
        'currentStreak': 0,
        'workoutTypes': {},
        'averageWorkoutDuration': 0,
      };
    }
  }
}
