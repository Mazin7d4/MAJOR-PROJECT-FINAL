import 'package:flutter/material.dart';
import '../../widgets/custom_button.dart';
import 'gender_age_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Add the app logo with rounded corners
            ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: Image.asset('assets/logo.png', width: 100, height: 100),
            ),
            const SizedBox(height: 20),
            const Text(
              "Welcome to Trackify App",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text(
              "This app helps you track calories, macros intake and get personalized AI advice.",
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            CustomButton(
              label: "Get Started",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GenderAgeScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
