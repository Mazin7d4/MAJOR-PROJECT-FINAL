import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../utils/tdee_calculator.dart'; // Adjust path as per your project structure
import 'activity_search_screen.dart'; // Adjust import as needed
import 'food_search_screen.dart'; // Adjust import as needed

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  double? calorieGoal;
  Map<String, double>? macros;
  double consumed = 0;
  double burned = 0;

  Map<String, int> mealData = {
    'Breakfast': 0,
    'Lunch': 0,
    'Dinner': 0,
    'Snacks': 0,
  };

  Map<String, List<Map<String, dynamic>>> mealEntries = {
    'Breakfast': [],
    'Lunch': [],
    'Dinner': [],
    'Snacks': [],
  };

  Map<String, double> macroTotals = {'carbs': 0, 'fat': 0, 'protein': 0};

  Map<String, int> activityData = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Observe app lifecycle
    _initializeHomeScreen();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Remove observer
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _saveCurrentDayData(); // Save data when app is paused or closed
    }
  }

  Future<void> _initializeHomeScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T').first;
    final lastDate = prefs.getString('last_active_date');

    // If the date has changed, reset data for the new day
    if (lastDate != today) {
      await prefs.setDouble('consumed', 0);
      await prefs.setDouble('burned', 0);
      for (var meal in mealData.keys) {
        await prefs.setInt('${meal.toLowerCase()}_cals', 0);
        await prefs.setDouble('${meal.toLowerCase()}_carbs', 0);
        await prefs.setDouble('${meal.toLowerCase()}_fat', 0);
        await prefs.setDouble('${meal.toLowerCase()}_protein', 0);
        await prefs.setStringList('${meal.toLowerCase()}_entries', []);
      }
      await prefs.setString('last_active_date', today);
      for (var key in prefs.getKeys()) {
        if (key.startsWith("activity_")) await prefs.remove(key);
      }
    }

    // Load today's data
    consumed = prefs.getDouble('consumed') ?? 0;
    burned = prefs.getDouble('burned') ?? 0;
    macroTotals = {'carbs': 0, 'fat': 0, 'protein': 0};

    for (var meal in mealData.keys) {
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
          (macroTotals['fat'] ?? 0) + (prefs.getDouble("${mealKey}_fat") ?? 0);
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

    await _loadUserData();
    setState(() {});
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final gender = prefs.getString('gender') ?? 'male';
    final dobString = prefs.getString('dob');
    final weight = prefs.getDouble('weight') ?? 70;
    final height = prefs.getDouble('height') ?? 175;
    final activity = prefs.getInt('activityLevel') ?? 1;
    final goal = prefs.getInt('goal') ?? 1;

    if (dobString == null) return;
    final dob = DateTime.parse(dobString);
    final age = DateTime.now().year - dob.year;
    final bmr = calculateBMR(
      gender: gender,
      weightKg: weight,
      heightCm: height,
      age: age,
    );
    final tdee = bmr * activityMultiplier(activity);

    setState(() {
      calorieGoal = tdee * (1 + goalAdjustment(goal));
      macros = calculateMacros(calorieGoal!);
    });

    // Save calorieGoal and macros to SharedPreferences immediately
    await prefs.setDouble('calorieGoal', calorieGoal!);
    await prefs.setDouble('macros_carbs', macros!['carbs']!);
    await prefs.setDouble('macros_fat', macros!['fat']!);
    await prefs.setDouble('macros_protein', macros!['protein']!);
  }

  Future<void> _saveCurrentDayData() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final dailyData = {
      'calorieGoal': calorieGoal ?? 0,
      'consumed': consumed,
      'burned': burned,
      'macros': macroTotals,
      'mealData': mealData,
      'mealEntries': mealEntries,
      'activityData': activityData,
    };

    await prefs.setString('diary_$today', json.encode(dailyData));
  }

  @override
  Widget build(BuildContext context) {
    if (calorieGoal == null || macros == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final remaining = calorieGoal! - consumed; // Adjusted calculation

    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            Colors.grey.shade900, // Set the background color to grey
        title: Row(
          children: [
            ClipOval(
              child: Image.asset(
                'assets/logo.png',
                width: 24,
                height: 24,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(
              width: 8,
            ), // Add spacing between the logo and the title
            const Text('Trackify'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDashboard(remaining),
            const SizedBox(height: 30),
            const Text(
              "Today's Meals",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            ...mealData.entries
                .map((entry) => _mealCard(context, entry.key, entry.value))
                .toList(),
            const SizedBox(height: 30),
            _buildActivities(),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(double remaining) => Column(
    children: [
      Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          border: Border.all(color: Colors.red),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          children: [
            const Text(
              "Calories Remaining",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "${remaining.toInt()} kcal",
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _calculateProgress(),
              backgroundColor: Colors.red.shade100,
              color: Colors.red,
              minHeight: 10,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _calorieTile("Consumed", consumed.toInt(), Icons.restaurant),
                _calorieTile("Burned", burned.toInt(), Icons.fitness_center),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _macroCard("Carbs", macroTotals['carbs']!, macros!['carbs']!),
          _macroCard("Protein", macroTotals['protein']!, macros!['protein']!),
          _macroCard("Fat", macroTotals['fat']!, macros!['fat']!),
        ],
      ),
    ],
  );

  Widget _calorieTile(String label, int value, IconData icon) => Column(
    children: [
      Icon(icon, size: 30, color: Colors.red),
      const SizedBox(height: 6),
      Text(
        "$value kcal",
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
    ],
  );

  Widget _macroCard(String label, double current, double total) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.grey.shade900,
      border: Border.all(color: Colors.red),
      borderRadius: BorderRadius.circular(10),
      boxShadow: [
        BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
      ],
    ),
    child: Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "${current.toInt()} / ${total.toInt()} g",
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
      ],
    ),
  );

  Widget _mealCard(BuildContext context, String mealName, int calories) {
    final entries = mealEntries[mealName] ?? [];
    final ValueNotifier<bool> isExpanded = ValueNotifier(false);

    return Card(
      color: Colors.grey.shade900,
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ValueListenableBuilder<bool>(
        valueListenable: isExpanded,
        builder: (context, expanded, child) {
          return ExpansionTile(
            leading: Icon(Icons.restaurant_menu, color: Colors.red, size: 28),
            title: Text(
              mealName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            subtitle: Text(
              "$calories kcal",
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  expanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  color: Colors.grey,
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.red),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FoodSearchScreen(mealName: mealName),
                      ),
                    ).then((_) async {
                      await _initializeHomeScreen();
                      await _saveCurrentDayData();
                    });
                  },
                ),
              ],
            ),
            onExpansionChanged: (bool expanded) {
              isExpanded.value = expanded;
            },
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
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _editMealEntry(mealName, entry),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteMealEntry(mealName, entry),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          );
        },
      ),
    );
  }

  Future<void> _editMealEntry(String meal, Map<String, dynamic> entry) async {
    final controller = TextEditingController(
      text: entry['quantity'].toString(),
    );

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor:
                Colors.grey.shade900, // Set the background color to dark grey
            title: const Text(
              "Edit Quantity",
              style: TextStyle(
                color: Colors.white,
              ), // Set the text color to white
            ),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(
                color: Colors.white,
              ), // Set the text color to white
              decoration: const InputDecoration(
                hintText: "Enter new quantity",
                hintStyle: TextStyle(
                  color: Colors.white70,
                ), // Set the hint text color to white with some opacity
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Cancel",
                  style: TextStyle(
                    color: Colors.red,
                  ), // Set the text color to red
                ),
              ),
              TextButton(
                onPressed: () async {
                  final newQty = double.tryParse(controller.text);
                  if (newQty == null) return;

                  // Delete the old entry
                  await _deleteMealEntry(meal, entry);

                  // Create the updated entry
                  final updated = {...entry};
                  updated['quantity'] = newQty;
                  updated['calories'] =
                      (entry['calories'] / entry['quantity']) * newQty;
                  updated['carbs'] =
                      (entry['carbs'] / entry['quantity']) * newQty;
                  updated['fat'] = (entry['fat'] / entry['quantity']) * newQty;
                  updated['protein'] =
                      (entry['protein'] / entry['quantity']) * newQty;

                  // Save the updated entry
                  final prefs = await SharedPreferences.getInstance();
                  final key = "${meal.toLowerCase()}_entries";
                  final list = prefs.getStringList(key) ?? [];
                  list.add(json.encode(updated));
                  await prefs.setStringList(key, list);

                  // Update meal data
                  mealEntries[meal] =
                      list
                          .map((e) => json.decode(e))
                          .cast<Map<String, dynamic>>()
                          .toList();
                  mealData[meal] = mealEntries[meal]!.fold<int>(
                    0,
                    (sum, item) => sum + (item['calories'] as num).toInt(),
                  );

                  // Recalculate macros
                  macroTotals['carbs'] = 0;
                  macroTotals['fat'] = 0;
                  macroTotals['protein'] = 0;
                  for (var mealEntriesList in mealEntries.values) {
                    for (var entry in mealEntriesList) {
                      macroTotals['carbs'] =
                          (macroTotals['carbs'] ?? 0) + (entry['carbs'] ?? 0);
                      macroTotals['fat'] =
                          (macroTotals['fat'] ?? 0) + (entry['fat'] ?? 0);
                      macroTotals['protein'] =
                          (macroTotals['protein'] ?? 0) +
                          (entry['protein'] ?? 0);
                    }
                  }

                  // Update SharedPreferences
                  await prefs.setInt(
                    "${meal.toLowerCase()}_cals",
                    mealData[meal] ?? 0,
                  );
                  await prefs.setDouble(
                    "${meal.toLowerCase()}_carbs",
                    macroTotals['carbs'] ?? 0.0,
                  );
                  await prefs.setDouble(
                    "${meal.toLowerCase()}_fat",
                    macroTotals['fat'] ?? 0.0,
                  );
                  await prefs.setDouble(
                    "${meal.toLowerCase()}_protein",
                    macroTotals['protein'] ?? 0.0,
                  );

                  // Update the total consumed calories
                  consumed =
                      mealData.values
                          .fold(0, (sum, value) => sum + value)
                          .toDouble();
                  await prefs.setDouble("consumed", consumed);

                  // Save the current day's data
                  await _saveCurrentDayData();

                  // Reload the home screen data
                  await _initializeHomeScreen();
                  Navigator.pop(context);
                },
                child: const Text(
                  "OK",
                  style: TextStyle(
                    color: Colors.green,
                  ), // Set the text color to green
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteMealEntry(String meal, Map<String, dynamic> entry) async {
    final prefs = await SharedPreferences.getInstance();
    final key = "${meal.toLowerCase()}_entries";
    final list = prefs.getStringList(key) ?? [];
    final updatedList = list.where((e) => e != json.encode(entry)).toList();
    await prefs.setStringList(key, updatedList);

    // Update meal data
    mealEntries[meal] =
        updatedList
            .map((e) => json.decode(e))
            .cast<Map<String, dynamic>>()
            .toList();
    mealData[meal] = mealEntries[meal]!.fold<int>(
      0,
      (sum, item) => sum + (item['calories'] as num).toInt(),
    );

    // Recalculate macros
    macroTotals['carbs'] = 0;
    macroTotals['fat'] = 0;
    macroTotals['protein'] = 0;
    for (var mealEntriesList in mealEntries.values) {
      for (var entry in mealEntriesList) {
        macroTotals['carbs'] =
            (macroTotals['carbs'] ?? 0) + (entry['carbs'] ?? 0);
        macroTotals['fat'] = (macroTotals['fat'] ?? 0) + (entry['fat'] ?? 0);
        macroTotals['protein'] =
            (macroTotals['protein'] ?? 0) + (entry['protein'] ?? 0);
      }
    }

    // Update SharedPreferences
    await prefs.setInt("${meal.toLowerCase()}_cals", mealData[meal] ?? 0);
    await prefs.setDouble(
      "${meal.toLowerCase()}_carbs",
      macroTotals['carbs'] ?? 0.0,
    );
    await prefs.setDouble(
      "${meal.toLowerCase()}_fat",
      macroTotals['fat'] ?? 0.0,
    );
    await prefs.setDouble(
      "${meal.toLowerCase()}_protein",
      macroTotals['protein'] ?? 0.0,
    );

    // Update the total consumed calories
    consumed = mealData.values.fold(0, (sum, value) => sum + value).toDouble();
    await prefs.setDouble("consumed", consumed);

    // Save the current day's data
    await _saveCurrentDayData();

    setState(() {});
  }

  Widget _buildActivities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Today's Activities",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle, color: Colors.red),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ActivitySearchScreen(),
                  ),
                ).then((_) async {
                  await _initializeHomeScreen();
                  await _saveCurrentDayData();
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (activityData.isEmpty)
          const Text(
            "No activities logged yet.",
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
        ...activityData.entries.map((entry) {
          return Card(
            color: Colors.grey.shade900,
            margin: const EdgeInsets.symmetric(vertical: 8),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const Icon(
                Icons.directions_run,
                color: Colors.blue,
                size: 28,
              ),
              title: Text(
                entry.key,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              subtitle: Text(
                "${entry.value} kcal burned",
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _editActivity(entry.key),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeActivity(entry.key),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Future<void> _editActivity(String name) async {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor:
                Colors.grey.shade900, // Set the background color to dark grey
            title: const Text(
              "Edit Duration (min)",
              style: TextStyle(
                color: Colors.white,
              ), // Set the text color to white
            ),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                color: Colors.white,
              ), // Set the text color to white
              decoration: const InputDecoration(
                hintText: "Enter new duration",
                hintStyle: TextStyle(
                  color: Colors.white70,
                ), // Set the hint text color to white with some opacity
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Cancel",
                  style: TextStyle(
                    color: Colors.red,
                  ), // Set the text color to red
                ),
              ),
              TextButton(
                onPressed: () async {
                  final mins = int.tryParse(controller.text);
                  if (mins == null) return;
                  final kcal = mins * 6;
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setInt("activity_$name", kcal);
                  activityData[name] = kcal; // Update activity data in memory
                  final burnedList =
                      prefs
                          .getKeys()
                          .where((k) => k.startsWith("activity_"))
                          .map((k) => prefs.getInt(k) ?? 0)
                          .toList();
                  burned = burnedList.fold(0, (a, b) => a + b).toDouble();
                  await prefs.setDouble('burned', burned);
                  await _saveCurrentDayData(); // Save updated data
                  await _initializeHomeScreen();
                  Navigator.pop(context);
                },
                child: const Text(
                  "OK",
                  style: TextStyle(
                    color: Colors.green,
                  ), // Set the text color to green
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _removeActivity(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final kcal = prefs.getInt("activity_$name") ?? 0;

    // Remove the activity from SharedPreferences
    await prefs.remove("activity_$name");

    // Update the burned calories
    final currentBurned = prefs.getDouble('burned') ?? 0;
    burned = (currentBurned - kcal).clamp(0, double.infinity);
    await prefs.setDouble('burned', burned);

    // Remove the activity from activityData
    activityData.remove(name);

    // Save the updated day's data
    await _saveCurrentDayData();

    // Reload the home screen data
    await _initializeHomeScreen();

    setState(() {});
  }

  double _calculateProgress() {
    if (calorieGoal == null || calorieGoal == 0) {
      return 0.0; // Avoid division by zero
    }

    // Calculate progress as consumed / calorieGoal
    final progress = consumed / calorieGoal!;

    // Clamp the progress value between 0.0 and 1.0
    return progress.clamp(0.0, 1.0);
  }
}
