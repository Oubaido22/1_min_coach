import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../screens/welcome_page.dart';
import '../screens/home_page.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        // Debug logging
        print('AuthWrapper: Connection state: ${snapshot.connectionState}');
        print('AuthWrapper: Has data: ${snapshot.hasData}');
        print('AuthWrapper: Has error: ${snapshot.hasError}');
        print('AuthWrapper: User: ${snapshot.data?.email}');
        
        // Show loading indicator while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Handle errors
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Authentication Error',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Restart the app or try again
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const AuthWrapper(),
                        ),
                      );
                    },
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          );
        }

        // If user is logged in, show home page
        if (snapshot.hasData && snapshot.data != null) {
          return const HomePage();
        }

        // If user is not logged in (null or no data), show welcome page
        return const WelcomePage();
      },
    );
  }
}
