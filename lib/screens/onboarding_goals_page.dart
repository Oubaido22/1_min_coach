import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'onboarding_measurements_page.dart';

class OnboardingGoalsPage extends StatefulWidget {
  const OnboardingGoalsPage({super.key});

  @override
  State<OnboardingGoalsPage> createState() => _OnboardingGoalsPageState();
}

class _OnboardingGoalsPageState extends State<OnboardingGoalsPage> {
  String? selectedGoal;

  final List<Map<String, dynamic>> goals = [
    {
      'title': 'Lose Weight',
      'subtitle': 'Burn calories and shed pounds',
      'icon': Icons.fitness_center,
    },
    {
      'title': 'Build Muscle',
      'subtitle': 'Gain strength and sculpt your physique',
      'icon': Icons.sports_gymnastics,
    },
    {
      'title': 'Improve Flexibility',
      'subtitle': 'Increase range of motion',
      'icon': Icons.accessibility_new,
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
                  'Step 1/3',
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
                  child: Row(
                    children: [
                      Container(
                        width: (MediaQuery.of(context).size.width - 80) / 3,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6A0DAD), // Primary Accent
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2A2A), // Dark gray
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Question
                Text(
                  "What's your primary goal?",
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 40),
                
                // Goal options
                Column(
                  children: goals.map((goal) {
                      final isSelected = selectedGoal == goal['title'];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedGoal = goal['title'];
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
                                  // Icon placeholder (using a simple container for now)
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2A2A2A),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      goal['icon'],
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
                                          goal['title'],
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
                                          goal['subtitle'],
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
                
                const SizedBox(height: 40),
                
                // Next button
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
                        if (selectedGoal != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OnboardingMeasurementsPage(
                                selectedGoal: selectedGoal,
                              ),
                            ),
                          );
                        }
                      },
                      child: Center(
                        child: Text(
                          'Next',
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
