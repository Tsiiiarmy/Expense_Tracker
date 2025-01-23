import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Navigate to the WelcomeScreen after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      Navigator.pushReplacementNamed(    //Replaces the current screen with a new one
          context, '/welcome'); // Navigate to WelcomeScreen
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color.fromARGB(255, 64, 185, 251).withOpacity(0.2),
              ),
              child: const Icon(
                Icons.track_changes, // Icon representing tracking/finance
                size: 60,
                color: Color.fromARGB(255, 64, 189, 251),
              ),
            ),
            const SizedBox(height: 20),

            // App Name
            const Text(
              'My Pocket',
              style: TextStyle(
                fontSize: 32,
                color: Color.fromARGB(255, 64, 201, 251),
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),

            // Tagline
            Text(
              'Your Personal Expense Guide',
              style: TextStyle(
                fontSize: 16,
                color: const Color.fromARGB(255, 64, 198, 251).withOpacity(0.8),
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 40),
            // Loading Indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                  Color.fromARGB(255, 64, 210, 251)),
            ),
          ],
        ),
      ),
    );
  }
}
