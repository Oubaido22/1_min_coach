class WorkoutPlan {
  final Map<String, List<String>> fullbodyPlan;
  final Map<String, List<String>> cardioPlan;

  WorkoutPlan({
    required this.fullbodyPlan,
    required this.cardioPlan,
  });

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) {
    return WorkoutPlan(
      fullbodyPlan: Map<String, List<String>>.from(
        json['fullbody_plan']?.map(
          (key, value) => MapEntry(key, List<String>.from(value)),
        ) ?? {},
      ),
      cardioPlan: Map<String, List<String>>.from(
        json['cardio_plan']?.map(
          (key, value) => MapEntry(key, List<String>.from(value)),
        ) ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullbody_plan': fullbodyPlan,
      'cardio_plan': cardioPlan,
    };
  }

  List<String> getFullbodyDay(String day) {
    return fullbodyPlan[day] ?? [];
  }

  List<String> getCardioDay(String day) {
    return cardioPlan[day] ?? [];
  }

  List<String> getAllDays() {
    return ['day1', 'day2', 'day3', 'day4', 'day5', 'day6', 'day7'];
  }

  String getDayDisplayName(String day) {
    switch (day) {
      case 'day1':
        return 'Monday';
      case 'day2':
        return 'Tuesday';
      case 'day3':
        return 'Wednesday';
      case 'day4':
        return 'Thursday';
      case 'day5':
        return 'Friday';
      case 'day6':
        return 'Saturday';
      case 'day7':
        return 'Sunday';
      default:
        return day;
    }
  }

  bool isRestDay(String day, String planType) {
    if (planType == 'fullbody') {
      return fullbodyPlan[day]?.contains('Rest Day') ?? false;
    } else if (planType == 'cardio') {
      return cardioPlan[day]?.contains('Rest Day') ?? false;
    }
    return false;
  }
}

class WorkoutDay {
  final String day;
  final String displayName;
  final List<String> exercises;
  final bool isRestDay;

  WorkoutDay({
    required this.day,
    required this.displayName,
    required this.exercises,
    required this.isRestDay,
  });

  factory WorkoutDay.fromPlan(String day, List<String> exercises) {
    return WorkoutDay(
      day: day,
      displayName: _getDayDisplayName(day),
      exercises: exercises,
      isRestDay: exercises.contains('Rest Day'),
    );
  }

  static String _getDayDisplayName(String day) {
    switch (day) {
      case 'day1':
        return 'Monday';
      case 'day2':
        return 'Tuesday';
      case 'day3':
        return 'Wednesday';
      case 'day4':
        return 'Thursday';
      case 'day5':
        return 'Friday';
      case 'day6':
        return 'Saturday';
      case 'day7':
        return 'Sunday';
      default:
        return day;
    }
  }
}
