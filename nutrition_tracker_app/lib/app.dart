import 'package:flutter/material.dart';
import 'config/theme.dart';
import 'screens/onboarding/welcome_screen.dart';
import 'screens/main_app/main_app.dart';

class TrackifyApp extends StatelessWidget {
  final bool isOnboardingDone;

  const TrackifyApp({super.key, required this.isOnboardingDone});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trackify',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: isOnboardingDone ? const MainApp() : const WelcomeScreen(),
    );
  }
}
