class ExerciseAnalysis {
  final List<String> detectedObjects;
  final List<ExerciseSuggestion> exerciseSuggestions;

  ExerciseAnalysis({
    required this.detectedObjects,
    required this.exerciseSuggestions,
  });

  factory ExerciseAnalysis.fromJson(Map<String, dynamic> json) {
    return ExerciseAnalysis(
      detectedObjects: List<String>.from(json['detected_objects'] ?? []),
      exerciseSuggestions: (json['exercise_suggestion'] as List<dynamic>?)
          ?.map((item) => ExerciseSuggestion.fromJson(item))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'detected_objects': detectedObjects,
      'exercise_suggestion': exerciseSuggestions.map((e) => e.toJson()).toList(),
    };
  }
}

class ExerciseSuggestion {
  final String exercise;
  final String instructions;

  ExerciseSuggestion({
    required this.exercise,
    required this.instructions,
  });

  factory ExerciseSuggestion.fromJson(Map<String, dynamic> json) {
    return ExerciseSuggestion(
      exercise: json['exercise'] ?? '',
      instructions: json['instructions'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exercise': exercise,
      'instructions': instructions,
    };
  }
}

class WorkoutSession {
  final String id;
  final DateTime startTime;
  final int duration; // in seconds
  final String? imagePath;
  final ExerciseAnalysis? analysis;
  final bool isCompleted;

  WorkoutSession({
    required this.id,
    required this.startTime,
    required this.duration,
    this.imagePath,
    this.analysis,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'duration': duration,
      'imagePath': imagePath,
      'analysis': analysis?.toJson(),
      'isCompleted': isCompleted,
    };
  }

  factory WorkoutSession.fromJson(Map<String, dynamic> json) {
    return WorkoutSession(
      id: json['id'] ?? '',
      startTime: DateTime.parse(json['startTime']),
      duration: json['duration'] ?? 0,
      imagePath: json['imagePath'],
      analysis: json['analysis'] != null 
          ? ExerciseAnalysis.fromJson(json['analysis']) 
          : null,
      isCompleted: json['isCompleted'] ?? false,
    );
  }
}
