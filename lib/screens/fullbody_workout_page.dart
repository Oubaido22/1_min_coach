import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/workout_plan.dart';

class FullbodyWorkoutPage extends StatefulWidget {
  final WorkoutPlan workoutPlan;

  const FullbodyWorkoutPage({
    super.key,
    required this.workoutPlan,
  });

  @override
  State<FullbodyWorkoutPage> createState() => _FullbodyWorkoutPageState();
}

class _FullbodyWorkoutPageState extends State<FullbodyWorkoutPage> {
  int _selectedDayIndex = 0;

  @override
  Widget build(BuildContext context) {
    final days = widget.workoutPlan.getAllDays();
    final currentDay = days[_selectedDayIndex];
    final exercises = widget.workoutPlan.getFullbodyDay(currentDay);
    final isRestDay = widget.workoutPlan.isRestDay(currentDay, 'fullbody');

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
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
                      'Full Body Workout Plan',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Day Selector
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: days.length,
                itemBuilder: (context, index) {
                  final day = days[index];
                  final isSelected = index == _selectedDayIndex;
                  final dayName = widget.workoutPlan.getDayDisplayName(day);
                  final isRest = widget.workoutPlan.isRestDay(day, 'fullbody');

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDayIndex = index;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? const Color(0xFF6A0DAD)
                            : const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(20),
                        border: isRest && isSelected
                            ? Border.all(color: const Color(0xFFFFC107), width: 2)
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            dayName.substring(0, 3), // Mon, Tue, etc.
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : const Color(0xFF9E9E9E),
                            ),
                          ),
                          if (isRest)
                            Icon(
                              Icons.bedtime,
                              size: 12,
                              color: isSelected ? const Color(0xFFFFC107) : const Color(0xFF9E9E9E),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Workout Content
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: isRestDay
                    ? _buildRestDayContent()
                    : _buildWorkoutContent(exercises, currentDay),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildRestDayContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFFFFC107).withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.bedtime,
            color: Color(0xFFFFC107),
            size: 40,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Rest Day',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Take a well-deserved break! Your body needs time to recover and rebuild.',
          style: GoogleFonts.inter(
            fontSize: 16,
            color: const Color(0xFF9E9E9E),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                'Recovery Tips',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFFFC107),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '• Stay hydrated\n• Get adequate sleep\n• Light stretching\n• Gentle walking',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF9E9E9E),
                ),
                textAlign: TextAlign.left,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWorkoutContent(List<String> exercises, String day) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF6A0DAD).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.fitness_center,
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
                    widget.workoutPlan.getDayDisplayName(day),
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Full Body Workout',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF9E9E9E),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        Text(
          'Exercises',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        
        const SizedBox(height: 16),
        
        Expanded(
          child: ListView.builder(
            itemCount: exercises.length,
            itemBuilder: (context, index) {
              final exercise = exercises[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6A0DAD),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        exercise,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.play_circle_outline,
                      color: const Color(0xFF6A0DAD),
                      size: 24,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Start Workout Button
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF6A0DAD),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                _showStartWorkoutDialog(exercises);
              },
              child: Center(
                child: Text(
                  'Start Workout',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showStartWorkoutDialog(List<String> exercises) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Start Full Body Workout',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Ready to begin your ${exercises.length} exercises?',
          style: GoogleFonts.inter(
            color: Colors.white,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: const Color(0xFF9E9E9E),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Navigate to workout execution page
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Workout started! (Feature coming soon)'),
                  backgroundColor: Color(0xFF6A0DAD),
                ),
              );
            },
            child: Text(
              'Start',
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
