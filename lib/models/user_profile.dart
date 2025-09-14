import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String email;
  final String fullName;
  final double? height; // in cm
  final double? weight; // in kg
  final String? objective; // fitness goal (Lose Weight, Build Muscle, etc.)
  final String? experienceLevel; // experience level (Beginner, Intermediate, Advanced)
  final int? sessionsPerDay; // number of workout sessions per day
  final String? profilePictureUrl;
  final String? userToken;
  final DateTime createdAt;
  final DateTime lastLoginAt;

  UserProfile({
    required this.uid,
    required this.email,
    required this.fullName,
    this.height,
    this.weight,
    this.objective,
    this.experienceLevel,
    this.sessionsPerDay,
    this.profilePictureUrl,
    this.userToken,
    required this.createdAt,
    required this.lastLoginAt,
  });

  // Convert UserProfile to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'height': height,
      'weight': weight,
      'objective': objective,
      'experienceLevel': experienceLevel,
      'sessionsPerDay': sessionsPerDay,
      'profilePictureUrl': profilePictureUrl,
      'userToken': userToken,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': Timestamp.fromDate(lastLoginAt),
    };
  }

  // Create UserProfile from Firestore document
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      height: map['height']?.toDouble(),
      weight: map['weight']?.toDouble(),
      objective: map['objective'],
      experienceLevel: map['experienceLevel'],
      sessionsPerDay: map['sessionsPerDay']?.toInt(),
      profilePictureUrl: map['profilePictureUrl'],
      userToken: map['userToken'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastLoginAt: (map['lastLoginAt'] as Timestamp).toDate(),
    );
  }

  // Create a copy of UserProfile with updated fields
  UserProfile copyWith({
    String? uid,
    String? email,
    String? fullName,
    double? height,
    double? weight,
    String? objective,
    String? experienceLevel,
    int? sessionsPerDay,
    String? profilePictureUrl,
    String? userToken,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      objective: objective ?? this.objective,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      sessionsPerDay: sessionsPerDay ?? this.sessionsPerDay,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      userToken: userToken ?? this.userToken,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  // Check if profile is complete
  bool get isComplete {
    return height != null && 
           weight != null && 
           objective != null && 
           experienceLevel != null &&
           sessionsPerDay != null &&
           profilePictureUrl != null;
  }

  // Get BMI
  double? get bmi {
    if (height != null && weight != null && height! > 0) {
      double heightInMeters = height! / 100; // Convert cm to meters
      return weight! / (heightInMeters * heightInMeters);
    }
    return null;
  }
}
