import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'onboarding_experience_page.dart';

class OnboardingMeasurementsPage extends StatefulWidget {
  final String? selectedGoal;
  final String fullName;
  final String email;
  
  const OnboardingMeasurementsPage({
    super.key,
    required this.selectedGoal,
    required this.fullName,
    required this.email,
  });

  @override
  State<OnboardingMeasurementsPage> createState() => _OnboardingMeasurementsPageState();
}

class _OnboardingMeasurementsPageState extends State<OnboardingMeasurementsPage> {
  double height = 170.0; // Default height in cm
  double weight = 70.0; // Default weight in kg

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
                  'Step 2/3',
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
                        width: (MediaQuery.of(context).size.width - 80) * 2 / 3,
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
                  "What's your height and weight?",
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 40),
                
                // Height section
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
                        'Height',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${height.toInt()} cm',
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
                          value: height,
                          min: 120.0,
                          max: 220.0,
                          divisions: 100,
                          onChanged: (value) {
                            setState(() {
                              height = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Weight section
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
                        'Weight',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${weight.toInt()} kg',
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
                          value: weight,
                          min: 30.0,
                          max: 150.0,
                          divisions: 120,
                          onChanged: (value) {
                            setState(() {
                              weight = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OnboardingExperiencePage(
                              selectedGoal: widget.selectedGoal,
                              height: height,
                              weight: weight,
                              fullName: widget.fullName,
                              email: widget.email,
                            ),
                          ),
                        );
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
