import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_page.dart';

class OnboardingExperiencePage extends StatefulWidget {
  final String? selectedGoal;
  final double height;
  final double weight;
  
  const OnboardingExperiencePage({
    super.key,
    required this.selectedGoal,
    required this.height,
    required this.weight,
  });

  @override
  State<OnboardingExperiencePage> createState() => _OnboardingExperiencePageState();
}

class _OnboardingExperiencePageState extends State<OnboardingExperiencePage> {
  String? selectedExperience;
  int sessionsPerDay = 1;

  final List<Map<String, dynamic>> experienceLevels = [
    {
      'title': 'Beginner',
      'subtitle': 'New to fitness and workouts',
      'icon': Icons.star_border,
    },
    {
      'title': 'Intermediate',
      'subtitle': 'Some experience with regular exercise',
      'icon': Icons.star_half,
    },
    {
      'title': 'Advanced',
      'subtitle': 'Experienced with various workout routines',
      'icon': Icons.star,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFF121212), // Neutral Dark
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Progress indicator
                const SizedBox(height: 20),
                Text(
                  'Step 3/3',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: const Color(0xFF9E9E9E), // Light gray
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Progress bar
                Container(
                  width: double.infinity,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A), // Dark gray
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Container(
                    width: double.infinity,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6A0DAD), // Primary Accent
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Question
                Text(
                  "What's your experience level?",
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 40),
                
                // Experience level options
                Column(
                  children: experienceLevels.map((level) {
                    final isSelected = selectedExperience == level['title'];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedExperience = level['title'];
                          });
                        },
                        child: Container(
                          width: double.infinity,
                          height: 75,
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? const Color(0xFF1A1A1A) // Slightly lighter when selected
                                : const Color(0xFF1E1E1E), // Default dark
                            borderRadius: BorderRadius.circular(12),
                            border: isSelected 
                                ? Border.all(
                                    color: const Color(0xFF6A0DAD), // Primary Accent
                                    width: 2,
                                  )
                                : null,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // Icon
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2A2A2A),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    level['icon'],
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                
                                const SizedBox(width: 16),
                                
                                // Text content
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        level['title'],
                                        style: GoogleFonts.inter(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        level['subtitle'],
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: const Color(0xFF9E9E9E), // Light gray
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 24),
                
                // Sessions per day section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'How many sessions per day?',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '$sessionsPerDay session${sessionsPerDay > 1 ? 's' : ''}',
                        style: GoogleFonts.inter(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF6A0DAD), // Primary Accent
                        ),
                      ),
                      const SizedBox(height: 20),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: const Color(0xFF6A0DAD), // Primary Accent
                          inactiveTrackColor: const Color(0xFF2A2A2A), // Dark gray
                          thumbColor: const Color(0xFF6A0DAD), // Primary Accent
                          overlayColor: const Color(0xFF6A0DAD).withOpacity(0.2),
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                        ),
                        child: Slider(
                          value: sessionsPerDay.toDouble(),
                          min: 1.0,
                          max: 5.0,
                          divisions: 4,
                          onChanged: (value) {
                            setState(() {
                              sessionsPerDay = value.toInt();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Complete button
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6A0DAD), // Primary Accent
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        if (selectedExperience != null) {
                          // Save onboarding data and navigate to main app
                          print('Onboarding completed!');
                          print('Goal: ${widget.selectedGoal}');
                          print('Height: ${widget.height} cm');
                          print('Weight: ${widget.weight} kg');
                          print('Experience: $selectedExperience');
                          print('Sessions per day: $sessionsPerDay');
                          
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HomePage(),
                            ),
                            (route) => false,
                          );
                        }
                      },
                      child: Center(
                        child: Text(
                          'Complete',
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
                
                const SizedBox(height: 16),
                
                // Skip text
                GestureDetector(
                  onTap: () {
                    // TODO: Navigate to main app or skip onboarding
                    print('Skip onboarding');
                  },
                  child: Text(
                    'Skip',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: const Color(0xFF9E9E9E), // Light gray
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
