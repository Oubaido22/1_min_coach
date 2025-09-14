import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/workout_plan.dart';
import '../models/user_profile.dart';

class WorkoutPlanService {
  // API endpoint - try different possible endpoints
  static const String _baseUrl = 'http://192.168.1.70:5678/workflow-test/workout';
  static const String _alternativeUrl = 'http://192.168.1.70:5678/workout';
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  /// Fetch workout plans based on user profile data
  Future<WorkoutPlan> fetchWorkoutPlans(UserProfile userProfile) async {
    // Prepare query parameters with user data
    final queryParams = {
      'fullName': userProfile.fullName,
      'email': userProfile.email,
      'height': userProfile.height.toString(),
      'weight': userProfile.weight.toString(),
      'objective': userProfile.objective,
      'experienceLevel': userProfile.experienceLevel,
      'sessionsPerDay': userProfile.sessionsPerDay.toString(),
    };

    print('Query parameters: $queryParams');

    // Try multiple endpoints
    final endpoints = [_baseUrl, _alternativeUrl];
    
    for (int i = 0; i < endpoints.length; i++) {
      try {
        final endpoint = endpoints[i];
        print('Trying endpoint ${i + 1}/${endpoints.length}: $endpoint');
        
        // Build URI with query parameters
        final uri = Uri.parse(endpoint).replace(queryParameters: queryParams);
        print('Request URL: $uri');

        // Make the GET API request
        final response = await http.get(
          uri,
          headers: {
            'Accept': 'application/json',
          },
        );

        print('API Response Status: ${response.statusCode}');
        print('API Response Body: ${response.body}');

        if (response.statusCode == 200) {
          final Map<String, dynamic> jsonData = json.decode(response.body);
          final workoutPlan = WorkoutPlan.fromJson(jsonData);
          
          print('✅ Successfully parsed workout plan from endpoint: $endpoint');
          return workoutPlan;
        } else {
          print('❌ Endpoint $endpoint returned status ${response.statusCode}');
          if (i == endpoints.length - 1) {
            throw 'All endpoints failed. Last error: ${response.statusCode} - ${response.body}';
          }
        }
      } catch (e) {
        print('❌ Error with endpoint ${endpoints[i]}: $e');
        if (i == endpoints.length - 1) {
          print('🔄 All endpoints failed, using mock data');
          return _getMockWorkoutPlan();
        }
      }
    }
    
    // This should never be reached, but just in case
    return _getMockWorkoutPlan();
  }

  /// Get mock workout plan for development/testing
  WorkoutPlan _getMockWorkoutPlan() {
    print('Using mock workout plan data');
    
    return WorkoutPlan.fromJson({
      "fullbody_plan": {
        "day1": [
          "Bodyweight Squats",
          "Incline Push-Ups",
          "Glute Bridges"
        ],
        "day2": [
          "Wall Push-Ups",
          "Step-Ups on Stairs",
          "Dead Bug Core Holds"
        ],
        "day3": [
          "Chair Dips",
          "Bodyweight Lunges",
          "Bird-Dog Holds"
        ],
        "day4": [
          "Rest Day"
        ],
        "day5": [
          "Incline Push-Ups",
          "Wall Sits",
          "Superman Hold"
        ],
        "day6": [
          "Bodyweight Squats",
          "Glute Bridges",
          "Modified Plank Holds"
        ],
        "day7": [
          "Rest Day"
        ]
      },
      "cardio_plan": {
        "day1": [
          "Brisk Walking - 25 mins",
          "High Knees - 3 x 30 sec",
          "Jumping Jacks - 3 x 20 reps"
        ],
        "day2": [
          "March in Place - 5 mins",
          "Shadow Boxing - 3 x 1 min",
          "Step-Ups - 3 x 15 per leg"
        ],
        "day3": [
          "Walking Intervals (Fast/Slow) - 30 mins",
          "Torso Twists - 3 x 20",
          "Jumping Jacks - 3 x 15 reps"
        ],
        "day4": [
          "Rest Day"
        ],
        "day5": [
          "Low Impact HIIT - 20 mins (march, air punches, knee lifts)",
          "Step Touches - 3 x 30 sec",
          "Butt Kicks - 3 x 20 reps"
        ],
        "day6": [
          "Brisk Walking - 35 mins",
          "Skaters (modified) - 3 x 20",
          "Arm Circles - 3 x 1 min"
        ],
        "day7": [
          "Rest Day"
        ]
      }
    });
  }

  /// Fetch workout plans with retry logic
  Future<WorkoutPlan> fetchWorkoutPlansWithRetry(
    UserProfile userProfile, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
  }) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        return await fetchWorkoutPlans(userProfile);
      } catch (e) {
        attempts++;
        print('Attempt $attempts failed: $e');
        
        if (attempts >= maxRetries) {
          print('All retry attempts failed, using mock data');
          return _getMockWorkoutPlan();
        }
        
        print('Retrying in ${retryDelay.inSeconds} seconds...');
        await Future.delayed(retryDelay);
      }
    }
    
    // This should never be reached, but just in case
    return _getMockWorkoutPlan();
  }

  /// Save workout plan to Firestore
  Future<void> saveWorkoutPlanToFirestore(WorkoutPlan workoutPlan) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw 'User not authenticated';
      }

      final workoutPlanData = {
        'fullbody_plan': workoutPlan.fullbodyPlan,
        'cardio_plan': workoutPlan.cardioPlan,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'userId': user.uid, // Add user ID for verification
      };

      print('Saving workout plan to Firestore for user: ${user.uid}');
      print('Fullbody plan days: ${workoutPlan.fullbodyPlan.keys.length}');
      print('Cardio plan days: ${workoutPlan.cardioPlan.keys.length}');

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('workout_plans')
          .doc('current_plan')
          .set(workoutPlanData, SetOptions(merge: false));

      print('✅ Workout plan saved to Firestore successfully');
      
      // Verify the save by reading it back
      final savedDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('workout_plans')
          .doc('current_plan')
          .get();
      
      if (savedDoc.exists) {
        print('✅ Verification: Workout plan confirmed in Firestore');
      } else {
        print('❌ Verification failed: Workout plan not found in Firestore');
      }
    } catch (e) {
      print('❌ Error saving workout plan to Firestore: $e');
      throw 'Failed to save workout plan: $e';
    }
  }

  /// Get workout plan from Firestore
  Future<WorkoutPlan?> getWorkoutPlanFromFirestore() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ No authenticated user found');
        return null;
      }

      print('🔍 Checking Firestore for workout plan for user: ${user.uid}');

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('workout_plans')
          .doc('current_plan')
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        print('✅ Found workout plan in Firestore');
        print('📅 Created at: ${data['createdAt']}');
        print('📅 Updated at: ${data['updatedAt']}');
        
        final workoutPlan = WorkoutPlan.fromJson({
          'fullbody_plan': data['fullbody_plan'],
          'cardio_plan': data['cardio_plan'],
        });
        
        print('📊 Fullbody plan days: ${workoutPlan.fullbodyPlan.keys.length}');
        print('📊 Cardio plan days: ${workoutPlan.cardioPlan.keys.length}');
        
        return workoutPlan;
      } else {
        print('❌ No workout plan found in Firestore');
        return null;
      }
    } catch (e) {
      print('❌ Error getting workout plan from Firestore: $e');
      return null;
    }
  }

  /// Fetch and save workout plan (used after signup)
  Future<WorkoutPlan> fetchAndSaveWorkoutPlan(UserProfile userProfile) async {
    try {
      print('🚀 Starting fetchAndSaveWorkoutPlan for user: ${userProfile.fullName}');
      
      // First try to get from Firestore
      final existingPlan = await getWorkoutPlanFromFirestore();
      if (existingPlan != null) {
        print('✅ Using existing workout plan from Firestore - no API call needed');
        return existingPlan;
      }

      // If not found, fetch from API
      print('🌐 No existing plan found, fetching new workout plan from API...');
      final workoutPlan = await fetchWorkoutPlansWithRetry(userProfile);
      
      // Save to Firestore
      print('💾 Saving new workout plan to Firestore...');
      await saveWorkoutPlanToFirestore(workoutPlan);
      
      print('✅ Workout plan fetch and save completed successfully');
      return workoutPlan;
    } catch (e) {
      print('❌ Error in fetchAndSaveWorkoutPlan: $e');
      print('🔄 Falling back to mock data');
      // Return mock data as fallback
      return _getMockWorkoutPlan();
    }
  }

  /// Check if workout plan exists in Firestore
  Future<bool> hasWorkoutPlanInFirestore() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return false;
      }

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('workout_plans')
          .doc('current_plan')
          .get();

      return doc.exists;
    } catch (e) {
      print('Error checking workout plan existence: $e');
      return false;
    }
  }

  /// Clear workout plan from Firestore (for testing or reset)
  Future<void> clearWorkoutPlanFromFirestore() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw 'User not authenticated';
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('workout_plans')
          .doc('current_plan')
          .delete();

      print('🗑️ Workout plan cleared from Firestore');
    } catch (e) {
      print('❌ Error clearing workout plan from Firestore: $e');
      throw 'Failed to clear workout plan: $e';
    }
  }
}
