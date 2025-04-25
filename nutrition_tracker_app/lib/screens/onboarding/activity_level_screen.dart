import 'package:flutter/material.dart';
import '../../widgets/custom_button.dart';
import 'goal_screen.dart';

class ActivityLevelScreen extends StatefulWidget {
  final String gender;
  final DateTime dob;
  final double weightKg;
  final double heightCm;

  const ActivityLevelScreen({
    super.key,
    required this.gender,
    required this.dob,
    required this.weightKg,
    required this.heightCm,
  });

  @override
  State<ActivityLevelScreen> createState() => _ActivityLevelScreenState();
}

class _ActivityLevelScreenState extends State<ActivityLevelScreen> {
  int? _selectedIndex;

  final List<Map<String, String>> _activityLevels = [
    {
      'title': 'Sedentary',
      'desc': 'Office job and mostly sitting, and no activities',
    },
    {
      'title': 'Less Active',
      'desc': 'Sitting and standing in job and light free time activities',
    },
    {
      'title': 'Active',
      'desc': 'Mostly standing or walking in job and free time activities',
    },
    {
      'title': 'Very Active',
      'desc':
          'Mostly walking, running or carrying weight in job and free time activities',
    },
  ];

  void _goToNext() {
    if (_selectedIndex != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => GoalScreen(
                gender: widget.gender,
                dob: widget.dob,
                weightKg: widget.weightKg,
                heightCm: widget.heightCm,
                activityLevelIndex: _selectedIndex!,
              ),
        ),
      );
    }
  }

  Widget _buildActivityTile(int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.red.shade900 : Colors.grey.shade800,
          border: Border.all(
            color: isSelected ? Colors.red : Colors.grey.shade600,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _activityLevels[index]['title']!,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _activityLevels[index]['desc']!,
              style: const TextStyle(fontSize: 15, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Activity Level")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              "Choose your daily activity level",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _activityLevels.length,
                itemBuilder: (context, index) => _buildActivityTile(index),
              ),
            ),
            CustomButton(
              label: "Next",
              onPressed: _selectedIndex != null ? _goToNext : () {},
            ),
          ],
        ),
      ),
      backgroundColor: Colors.black,
    );
  }
}
