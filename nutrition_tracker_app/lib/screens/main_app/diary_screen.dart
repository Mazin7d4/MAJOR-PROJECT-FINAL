import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  DateTime selectedDate = DateTime.now();
  Map<String, int> mealData = {};
  Map<String, List<Map<String, dynamic>>> mealEntries = {};
  Map<String, double> macroTotals = {};
  int consumed = 0;
  double burned = 0;
  double? calorieGoal;

  Map<String, double>? macros;
  Map<String, int> activityData = {};

  final List<String> mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snacks'];

  @override
  void initState() {
    super.initState();
    _loadDataForDate(selectedDate);
  }

  Future<void> _loadDataForDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final isToday =
        date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;

    if (isToday) {
      // Load data from individual keys for the current day
      consumed = (prefs.getDouble('consumed') ?? 0).toInt();
      burned = prefs.getDouble('burned') ?? 0;
      macroTotals = {'carbs': 0, 'fat': 0, 'protein': 0};

      for (var meal in mealTypes) {
        final mealKey = meal.toLowerCase();
        mealData[meal] = prefs.getInt("${mealKey}_cals") ?? 0;
        final entriesJson = prefs.getStringList("${mealKey}_entries") ?? [];
        mealEntries[meal] =
            entriesJson
                .map((e) => json.decode(e))
                .cast<Map<String, dynamic>>()
                .toList();
        macroTotals['carbs'] =
            (macroTotals['carbs'] ?? 0) +
            (prefs.getDouble("${mealKey}_carbs") ?? 0);
        macroTotals['fat'] =
            (macroTotals['fat'] ?? 0) +
            (prefs.getDouble("${mealKey}_fat") ?? 0);
        macroTotals['protein'] =
            (macroTotals['protein'] ?? 0) +
            (prefs.getDouble("${mealKey}_protein") ?? 0);
      }

      activityData = {};
      for (String key in prefs.getKeys()) {
        if (key.startsWith("activity_")) {
          final name = key.replaceFirst("activity_", "");
          activityData[name] = prefs.getInt(key) ?? 0;
        }
      }

      // Load calorie goal and macros for the current day
      calorieGoal = prefs.getDouble('calorieGoal');
      macros = {
        'carbs': prefs.getDouble('macros_carbs') ?? 0,
        'fat': prefs.getDouble('macros_fat') ?? 0,
        'protein': prefs.getDouble('macros_protein') ?? 0,
      };
    } else {
      // Load data from 'diary_YYYY-MM-dd' for past dates
      final keyDate = DateFormat('yyyy-MM-dd').format(date);
      final diaryDataString = prefs.getString('diary_$keyDate');
      if (diaryDataString != null) {
        final diaryData = json.decode(diaryDataString);
        print("Loaded data for $keyDate: $diaryData"); // Debug print
        calorieGoal = diaryData['calorieGoal']?.toDouble();
        consumed = diaryData['consumed']?.toInt() ?? 0;
        burned = diaryData['burned']?.toDouble() ?? 0;
        macros = Map<String, double>.from(diaryData['macros'] ?? {});
        mealData = Map<String, int>.from(diaryData['mealData'] ?? {});
        mealEntries = Map<String, List<Map<String, dynamic>>>.from(
          (diaryData['mealEntries'] ?? {}).map(
            (key, value) =>
                MapEntry(key, List<Map<String, dynamic>>.from(value)),
          ),
        );
        activityData = Map<String, int>.from(diaryData['activityData'] ?? {});
        macroTotals = {
          'carbs': macros?['carbs'] ?? 0,
          'fat': macros?['fat'] ?? 0,
          'protein': macros?['protein'] ?? 0,
        };
      } else {
        // Default values if no data exists for the date
        calorieGoal = 0;
        consumed = 0;
        burned = 0;
        macros = {'carbs': 0, 'fat': 0, 'protein': 0};
        macroTotals = {'carbs': 0, 'fat': 0, 'protein': 0};
        mealData = {'Breakfast': 0, 'Lunch': 0, 'Dinner': 0, 'Snacks': 0};
        mealEntries = {
          'Breakfast': [],
          'Lunch': [],
          'Dinner': [],
          'Snacks': [],
        };
        activityData = {};
      }
    }

    setState(() {});
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
              Icons.calendar_today, // Use the calendar icon for the diary logo
              color: Colors.white, // Set the color to white
              size: 24, // Adjust the size as needed
            ),
            const SizedBox(
              width: 8,
            ), // Add spacing between the logo and the title
            const Text('Diary'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCalendarHeader(),
              const SizedBox(height: 16),
              _buildCalendar(),
              const SizedBox(height: 16),
              const SizedBox(height: 16), // Add space on top of the date text
              Text(
                DateFormat('EEEE, d MMMM yyyy').format(selectedDate),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // Set the text color to white
                ),
              ),
              const SizedBox(height: 16),
              // Modernized UI for displaying stats
              Card(
                color: Colors.grey.shade900, // Set the card color to dark grey
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _statRow(
                        Icons.local_fire_department,
                        "Calories",
                        "$consumed / ${calorieGoal?.toInt() ?? 0} kcal",
                      ),
                      const SizedBox(height: 12),
                      _statRow(
                        Icons.rice_bowl,
                        "Carbs",
                        "${macroTotals['carbs']?.toInt() ?? 0} g",
                      ),
                      const SizedBox(height: 12),
                      _statRow(
                        Icons.fastfood,
                        "Fat",
                        "${macroTotals['fat']?.toInt() ?? 0} g",
                      ),
                      const SizedBox(height: 12),
                      _statRow(
                        Icons.fitness_center,
                        "Protein",
                        "${macroTotals['protein']?.toInt() ?? 0} g",
                      ),
                      const SizedBox(height: 12),
                      _statRow(
                        Icons.directions_run,
                        "Burned",
                        "${burned.toInt()} kcal",
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Meals",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              ...mealData.entries.map(
                (e) =>
                    _buildMealEntry(e.key, e.value, mealEntries[e.key] ?? []),
              ),
              const SizedBox(height: 16),
              const Text(
                "Activities",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              if (activityData.isEmpty)
                const Text(
                  "No activities logged yet.",
                  style: TextStyle(color: Colors.white70),
                ),
              ...activityData.entries.map(
                (e) => _buildActivityEntry(e.key, e.value),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_left, color: Colors.white),
          onPressed: () => _changeMonth(-1),
        ),
        Text(
          DateFormat('MMMM yyyy').format(selectedDate),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_right, color: Colors.white),
          onPressed: () => _changeMonth(1),
        ),
      ],
    );
  }

  Widget _buildCalendar() {
    final firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    final daysInMonth =
        DateTime(selectedDate.year, selectedDate.month + 1, 0).day;
    final firstWeekday = firstDayOfMonth.weekday;
    final today = DateTime.now();

    return Column(
      children: [
        SizedBox(
          height: 278, // Increased height to prevent numbers from being cut off
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: daysInMonth + firstWeekday - 1,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7, // 7 days in a week
              mainAxisSpacing: 4, // Add spacing between rows
              crossAxisSpacing: 4, // Add spacing between columns
            ),
            itemBuilder: (context, index) {
              if (index < firstWeekday - 1) return const SizedBox();

              final day = index - firstWeekday + 2;
              final date = DateTime(selectedDate.year, selectedDate.month, day);
              final isToday =
                  date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day;
              final isSelected = date.day == selectedDate.day;

              return GestureDetector(
                onTap: () async {
                  setState(() => selectedDate = date);
                  await _loadDataForDate(date);
                },
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? Colors.red
                            : isToday
                            ? const Color.fromARGB(255, 255, 205, 205)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 16, // Ensure the font size fits well
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMealEntry(
    String meal,
    int kcal,
    List<Map<String, dynamic>> entries,
  ) {
    return Card(
      color: Colors.grey.shade900, // Set the card color to dark grey
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Icon(Icons.restaurant_menu, color: Colors.red, size: 28),
        title: Text(
          meal,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          "$kcal kcal",
          style: const TextStyle(fontSize: 14, color: Colors.white70),
        ),
        children:
            entries.map((entry) {
              return ListTile(
                leading: const Icon(
                  Icons.fastfood,
                  color: Colors.orange,
                  size: 24,
                ),
                title: Text(
                  entry['name'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                subtitle: Text(
                  "${entry['calories'].toStringAsFixed(0)} kcal — ${entry['quantity']}x",
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildActivityEntry(String activity, int kcal) {
    return Card(
      color: Colors.grey.shade900, // Set the card color to dark grey
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(
          Icons.directions_run, // Use a running icon for activities
          color: Colors.blue, // Set the color to blue for better contrast
          size: 28, // Adjust the size as needed
        ),
        title: Text(
          activity,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          "$kcal kcal burned",
          style: const TextStyle(fontSize: 14, color: Colors.white70),
        ),
      ),
    );
  }

  void _changeMonth(int delta) {
    setState(() {
      selectedDate = DateTime(selectedDate.year, selectedDate.month + delta, 1);
    });
    _loadDataForDate(selectedDate);
  }

  Widget _statRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 24, color: Colors.red),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
