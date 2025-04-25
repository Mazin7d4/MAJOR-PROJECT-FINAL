import 'package:flutter/material.dart';
import '../../widgets/custom_button.dart';
import 'overview_screen.dart';

class GoalScreen extends StatefulWidget {
  final String gender;
  final DateTime dob;
  final double weightKg;
  final double heightCm;
  final int activityLevelIndex;

  const GoalScreen({
    super.key,
    required this.gender,
    required this.dob,
    required this.weightKg,
    required this.heightCm,
    required this.activityLevelIndex,
  });

  @override
  State<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  int? _selectedIndex;

  final List<Map<String, String>> _goals = [
    {'title': 'Lose Weight', 'desc': 'Consume fewer calories than you burn'},
    {'title': 'Maintain Weight', 'desc': 'Consume the same calories you burn'},
    {'title': 'Gain Weight', 'desc': 'Consume more calories than you burn'},
  ];

  void _goToNext() {
    if (_selectedIndex != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => OverviewScreen(
                gender: widget.gender,
                dob: widget.dob,
                weightKg: widget.weightKg,
                heightCm: widget.heightCm,
                activityLevelIndex: widget.activityLevelIndex,
                goalIndex: _selectedIndex!,
              ),
        ),
      );
    }
  }

  Widget _buildGoalTile(int index) {
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
              _goals[index]['title']!,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _goals[index]['desc']!,
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
      appBar: AppBar(title: const Text("Your Goal")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              "What's your health goal?",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _goals.length,
                itemBuilder: (context, index) => _buildGoalTile(index),
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
