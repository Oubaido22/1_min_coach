import 'package:flutter/material.dart';
import 'screens/welcome_page.dart';
import 'screens/home_page.dart';

void main() {
  runApp(const OneMinuteCoachApp());
}

class OneMinuteCoachApp extends StatelessWidget {
  const OneMinuteCoachApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'One Minute Coach',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6A0DAD), // Primary Accent
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Inter',
      ),
      home: const WelcomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}