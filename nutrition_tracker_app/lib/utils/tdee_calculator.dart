double calculateBMR({
  required String gender,
  required double weightKg,
  required double heightCm,
  required int age,
}) {
  if (gender == 'male') {
    return 10 * weightKg + 6.25 * heightCm - 5 * age + 5;
  } else {
    return 10 * weightKg + 6.25 * heightCm - 5 * age - 161;
  }
}

double activityMultiplier(int activityLevelIndex) {
  switch (activityLevelIndex) {
    case 0: return 1.2;   // Sedentary
    case 1: return 1.375; // Less active
    case 2: return 1.55;  // Active
    case 3: return 1.725; // Very active
    default: return 1.2;
  }
}

double goalAdjustment(int goalIndex) {
  switch (goalIndex) {
    case 0: return -0.2; // Lose weight
    case 1: return 0.0;  // Maintain
    case 2: return 0.2;  // Gain weight
    default: return 0.0;
  }
}

Map<String, double> calculateMacros(double calorieGoal) {
  double protein = (calorieGoal * 0.3) / 4;
  double fat = (calorieGoal * 0.25) / 9;
  double carbs = (calorieGoal * 0.45) / 4;
  return {
    'protein': protein,
    'fat': fat,
    'carbs': carbs,
  };
}
