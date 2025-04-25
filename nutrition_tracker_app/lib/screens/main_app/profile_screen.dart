import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  double weight = 70;
  double height = 175;
  String gender = "male";
  String goal = "Maintain";
  String activity = "Sedentary";
  DateTime? dob;

  double bmi = 0;
  String bmiCategory = "";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      weight = prefs.getDouble('weight') ?? 70;
      height = prefs.getDouble('height') ?? 175;
      gender = prefs.getString('gender') ?? 'male';
      final goalIndex = prefs.getInt('goal') ?? 1;
      final activityIndex = prefs.getInt('activityLevel') ?? 1;

      final dobString = prefs.getString('dob');
      if (dobString != null) dob = DateTime.parse(dobString);

      goal = ["Lose", "Maintain", "Gain"][goalIndex];
      activity =
          [
            "Sedentary",
            "Light",
            "Moderate",
            "Active",
            "Very Active",
          ][activityIndex];

      _calculateBMI();
    });
  }

  void _calculateBMI() {
    if (height > 0 && weight > 0) {
      final h = height / 100;
      bmi = weight / pow(h, 2);
      if (bmi < 18.5) {
        bmiCategory = "Underweight";
      } else if (bmi < 25) {
        bmiCategory = "Normal";
      } else if (bmi < 30) {
        bmiCategory = "Overweight";
      } else {
        bmiCategory = "Obese";
      }
    }
  }

  int get age {
    if (dob == null) return 0;
    final now = DateTime.now();
    int age = now.year - dob!.year;
    if (now.month < dob!.month ||
        (now.month == dob!.month && now.day < dob!.day)) {
      age--;
    }
    return age;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            Colors.grey.shade900, // Set the background color to grey
        title: Row(
          children: [
            const Icon(
              Icons.person, // Use the person icon for the profile logo
              color: Colors.white, // Set the color to white
              size: 24, // Adjust the size as needed
            ),
            const SizedBox(
              width: 8,
            ), // Add spacing between the logo and the title
            const Text('Profile'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // --- BMI Section ---
            Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        Colors
                            .grey
                            .shade900, // Set the background color to dark grey
                    border: Border.all(color: Colors.red, width: 4),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    bmi.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // Set the text color to white
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // --- BMI Category Tab ---
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(
                      48,
                      158,
                      158,
                      158,
                    ), // Keep the background color green
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "BMI :", // Replace the icon with the text "BMI"
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        bmiCategory,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            _infoTile("Age", "$age", icon: Icons.cake, onEdit: _editDOB),
            _infoTile(
              "Weight (kg)",
              "$weight",
              icon: Icons.monitor_weight,
              onEdit:
                  () => _editValue("Weight", weight, (val) {
                    setState(() => weight = val);
                    _saveToPrefs("weight", val);
                  }),
            ),
            _infoTile(
              "Height (cm)",
              "$height",
              icon: Icons.height,
              onEdit:
                  () => _editValue("Height", height, (val) {
                    setState(() => height = val);
                    _saveToPrefs("height", val);
                  }),
            ),
            _infoTile("Goal", goal, icon: Icons.flag, onEdit: _editGoal),
            _infoTile(
              "Activity Level",
              activity,
              icon: Icons.directions_walk,
              onEdit: _editActivity,
            ),
            _infoTile(
              "Gender",
              gender,
              icon: Icons.person,
              onEdit: _editGender,
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(
    String label,
    String value, {
    required IconData icon,
    VoidCallback? onEdit,
  }) {
    return Card(
      color: Colors.grey.shade900, // Set the card color to dark grey
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          12,
        ), // Set the border radius to make it rounded
      ),
      margin: const EdgeInsets.symmetric(vertical: 8), // Add vertical margin
      child: ListTile(
        leading: Icon(icon, color: Colors.red),
        title: Text(
          label,
          style: const TextStyle(color: Colors.white),
        ), // Set the text color to white
        subtitle: Text(
          value,
          style: const TextStyle(fontSize: 16, color: Colors.white70),
        ), // Set the text color to white with some opacity
        trailing:
            onEdit != null ? const Icon(Icons.edit, color: Colors.red) : null,
        onTap: onEdit,
      ),
    );
  }

  void _editValue(String label, double current, Function(double) onSave) {
    final controller = TextEditingController(text: current.toString());
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor:
                Colors.grey.shade900, // Set the background color to dark grey
            title: Text(
              "Edit $label",
              style: const TextStyle(color: Colors.white),
            ), // Set the text color to white
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                hintText: "Enter new value",
                hintStyle: TextStyle(color: Colors.white70),
              ), // Set the hint text color to white with some opacity
              style: const TextStyle(
                color: Colors.white,
              ), // Set the text color to white
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.red),
                ), // Set the text color to red
              ),
              TextButton(
                onPressed: () {
                  final newVal = double.tryParse(controller.text);
                  if (newVal != null) {
                    onSave(newVal);
                  }
                  Navigator.pop(context);
                },
                child: const Text(
                  "Save",
                  style: TextStyle(color: Colors.green),
                ), // Set the text color to green
              ),
            ],
          ),
    );
  }

  void _editDOB() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: dob ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: Colors.red, // Header background color
              onPrimary: Colors.white, // Header text color
              surface: Colors.grey.shade900, // Background color
              onSurface: Colors.white, // Text color
            ),
            // Dialog background color
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => dob = picked);
      _saveToPrefs('dob', picked.toIso8601String());
    }
  }

  void _editGoal() {
    final options = ["Lose", "Maintain", "Gain"];
    _selectOption("Goal", options, options.indexOf(goal), (index) {
      setState(() => goal = options[index]);
      _saveToPrefs("goal", index);
    });
  }

  void _editActivity() {
    final options = ["Sedentary", "Light", "Moderate", "Active", "Very Active"];
    _selectOption("Activity Level", options, options.indexOf(activity), (
      index,
    ) {
      setState(() => activity = options[index]);
      _saveToPrefs("activityLevel", index);
    });
  }

  void _editGender() {
    final options = ["male", "female"];
    _selectOption("Gender", options, options.indexOf(gender), (index) {
      setState(() => gender = options[index]);
      _saveToPrefs("gender", options[index]);
    });
  }

  void _selectOption(
    String title,
    List<String> options,
    int selectedIndex,
    Function(int) onSelect,
  ) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor:
                Colors.grey.shade900, // Set the background color to dark grey
            title: Text(
              "Edit $title",
              style: const TextStyle(color: Colors.white),
            ), // Set the text color to white
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  options.asMap().entries.map((entry) {
                    final index = entry.key;
                    final value = entry.value;
                    return RadioListTile(
                      value: index,
                      groupValue: selectedIndex,
                      title: Text(
                        value,
                        style: const TextStyle(color: Colors.white),
                      ), // Set the text color to white
                      onChanged: (val) {
                        onSelect(val as int);
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
            ),
          ),
    );
  }

  Future<void> _saveToPrefs(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is double) {
      await prefs.setDouble(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
    _calculateBMI();
  }
}
