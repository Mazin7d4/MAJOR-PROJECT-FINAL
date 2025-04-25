import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final bool isOnboardingDone = prefs.getBool('onboarding_complete') ?? false;

  runApp(TrackifyApp(isOnboardingDone: isOnboardingDone));
}
