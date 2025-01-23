import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_pocket/screens/welcome_screen.dart'; // Replace with the actual path to your Welcome screen

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontSize: 22.0),
        ),
        backgroundColor: const Color.fromARGB(255, 39, 137, 176),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            try {
              await FirebaseAuth.instance.signOut(); // Log out the user
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const WelcomeScreen()),
              );
            } catch (e) {
              print("Error logging out: $e");
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 54, 203, 244),
          ),
          child: const Text('Logout'),
        ),
      ),
    );
  }
}
