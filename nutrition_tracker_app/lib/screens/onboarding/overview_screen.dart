import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/tdee_calculator.dart';
import '../../widgets/custom_button.dart';
import '../main_app/main_app.dart';

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({
    super.key,
    required this.gender,
    required this.dob,
    required this.weightKg,
    required this.heightCm,
    required this.activityLevelIndex,
    required this.goalIndex,
  });

  final String gender;
  final DateTime dob;
  final double weightKg;
  final double heightCm;
  final int activityLevelIndex;
  final int goalIndex;

  int calculateAge(DateTime dob) {
    final today = DateTime.now();
    int age = today.year - dob.year;
    if (today.month < dob.month ||
        (today.month == dob.month && today.day < dob.day)) {
      age--;
    }
    return age;
  }

  @override
  Widget build(BuildContext context) {
    final int age = calculateAge(dob);
    final bmr = calculateBMR(
      gender: gender,
      weightKg: weightKg,
      heightCm: heightCm,
      age: age,
    );
    final tdee = bmr * activityMultiplier(activityLevelIndex);
    final calorieGoal = tdee * (1 + goalAdjustment(goalIndex));
    final macros = calculateMacros(calorieGoal);

    return Scaffold(
      appBar: AppBar(title: const Text("Overview")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              "Your Daily Goals",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Calories: ${calorieGoal.toInt()} kcal",
              style: const TextStyle(fontSize: 20, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _macroCard("Carbs", macros['carbs']!),
                _macroCard("Protein", macros['protein']!),
                _macroCard("Fat", macros['fat']!),
              ],
            ),
            const Spacer(),
            CustomButton(
              label: "Start",
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('onboarding_complete', true);
                await prefs.setString('gender', gender);
                await prefs.setString('dob', dob.toIso8601String());
                await prefs.setDouble('weight', weightKg);
                await prefs.setDouble('height', heightCm);
                await prefs.setInt('activityLevel', activityLevelIndex);
                await prefs.setInt('goal', goalIndex);

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const MainApp()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
      backgroundColor: Colors.black,
    );
  }

  Widget _macroCard(String label, double grams) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "${grams.toInt()}g",
          style: const TextStyle(fontSize: 18, color: Colors.white),
        ),
      ],
    );
  }
}
