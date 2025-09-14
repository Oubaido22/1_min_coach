import 'package:cloud_firestore/cloud_firestore.dart';

class WorkoutHistory {
  final String id;
  final String userId;
  final DateTime completedAt;
  final int durationMinutes;
  final String workoutType;
  final String? notes;
  final Map<String, dynamic>? workoutData; // Additional workout-specific data
  final DateTime createdAt;

  WorkoutHistory({
    required this.id,
    required this.userId,
    required this.completedAt,
    required this.durationMinutes,
    required this.workoutType,
    this.notes,
    this.workoutData,
    required this.createdAt,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'completedAt': completedAt.toIso8601String(),
      'durationMinutes': durationMinutes,
      'workoutType': workoutType,
      'notes': notes,
      'workoutData': workoutData,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create from Map (from Firestore)
  factory WorkoutHistory.fromMap(Map<String, dynamic> map) {
    // Helper function to convert timestamp to DateTime
    DateTime _parseTimestamp(dynamic timestamp) {
      if (timestamp == null) return DateTime.now();
      
      if (timestamp is Timestamp) {
        return timestamp.toDate();
      } else if (timestamp is String) {
        return DateTime.parse(timestamp);
      } else {
        return DateTime.now();
      }
    }

    return WorkoutHistory(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      completedAt: _parseTimestamp(map['completedAt']),
      durationMinutes: map['durationMinutes'] ?? 0,
      workoutType: map['workoutType'] ?? '',
      notes: map['notes'],
      workoutData: map['workoutData'],
      createdAt: _parseTimestamp(map['createdAt']),
    );
  }

  // Copy with method for updates
  WorkoutHistory copyWith({
    String? id,
    String? userId,
    DateTime? completedAt,
    int? durationMinutes,
    String? workoutType,
    String? notes,
    Map<String, dynamic>? workoutData,
    DateTime? createdAt,
  }) {
    return WorkoutHistory(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      completedAt: completedAt ?? this.completedAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      workoutType: workoutType ?? this.workoutType,
      notes: notes ?? this.notes,
      workoutData: workoutData ?? this.workoutData,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'WorkoutHistory(id: $id, userId: $userId, completedAt: $completedAt, durationMinutes: $durationMinutes, workoutType: $workoutType, notes: $notes, workoutData: $workoutData, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkoutHistory &&
        other.id == id &&
        other.userId == userId &&
        other.completedAt == completedAt &&
        other.durationMinutes == durationMinutes &&
        other.workoutType == workoutType &&
        other.notes == notes &&
        other.workoutData == workoutData &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        completedAt.hashCode ^
        durationMinutes.hashCode ^
        workoutType.hashCode ^
        notes.hashCode ^
        workoutData.hashCode ^
        createdAt.hashCode;
  }
}
