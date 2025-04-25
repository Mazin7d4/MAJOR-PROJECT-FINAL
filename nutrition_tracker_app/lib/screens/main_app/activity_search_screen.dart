import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ActivitySearchScreen extends StatefulWidget {
  const ActivitySearchScreen({super.key});

  @override
  State<ActivitySearchScreen> createState() => _ActivitySearchScreenState();
}

class _ActivitySearchScreenState extends State<ActivitySearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> _allActivities = [
    {'name': 'Running', 'met': 9.8},
    {'name': 'Walking', 'met': 3.5},
    {'name': 'Cycling', 'met': 7.5},
    {'name': 'Jump Rope', 'met': 12.3},
    {'name': 'Swimming', 'met': 8.0},
    {'name': 'Dancing', 'met': 5.0},
    {'name': 'Tennis', 'met': 7.3},
    {'name': 'Basketball', 'met': 6.5},
    {'name': 'Soccer', 'met': 7.0},
    {'name': 'Yoga', 'met': 3.0},
    {'name': 'Weightlifting', 'met': 6.0},
  ];

  List<Map<String, dynamic>> _filteredActivities = [];

  @override
  void initState() {
    super.initState();
    _filteredActivities = _allActivities;
  }

  void _filterActivities(String query) {
    setState(() {
      _filteredActivities =
          _allActivities
              .where(
                (a) => a['name'].toLowerCase().contains(query.toLowerCase()),
              )
              .toList();
    });
  }

  void _onActivityTap(BuildContext context, Map<String, dynamic> activity) {
    showDialog(
      context: context,
      builder: (context) => _showMinuteDialog(activity),
    );
  }

  Widget _showMinuteDialog(Map<String, dynamic> activity) {
    final TextEditingController minuteController = TextEditingController();

    return AlertDialog(
      backgroundColor:
          Colors.grey.shade900, // Set the background color to dark grey
      title: Text(
        "How many minutes of ${activity['name']}?",
        style: const TextStyle(
          color: Colors.white,
        ), // Set the text color to white
      ),
      content: TextField(
        controller: minuteController,
        keyboardType: TextInputType.number,
        style: const TextStyle(
          color: Colors.white,
        ), // Set the text color to white
        decoration: const InputDecoration(
          hintText: "Enter minutes",
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
            style: TextStyle(color: Colors.red), // Set the text color to red
          ),
        ),
        TextButton(
          onPressed: () async {
            final minutes = int.tryParse(minuteController.text);
            if (minutes != null && minutes > 0) {
              await _saveActivity(activity['name'], activity['met'], minutes);
              if (!mounted) return;
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // return to HomeScreen
            }
          },
          child: const Text(
            "Add",
            style: TextStyle(
              color: Colors.green,
            ), // Set the text color to green
          ),
        ),
      ],
    );
  }

  Future<void> _saveActivity(String name, double met, int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    final weight = prefs.getDouble('weight') ?? 70.0;

    final calories = (met * weight * 0.0175 * minutes).toInt();

    // Save under activity key
    final key = 'activity_$name';
    final existing = prefs.getInt(key) ?? 0;
    await prefs.setInt(key, existing + calories);

    // Update total burned
    final burned = prefs.getDouble('burned') ?? 0;
    await prefs.setDouble('burned', burned + calories);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            Colors.grey.shade900, // Set the background color to grey
        title: const Text("Search Activities"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _filterActivities,
              decoration: InputDecoration(
                hintText: "Search activity...",
                hintStyle: const TextStyle(
                  color: Colors.white70,
                ), // Set the hint text color to white with some opacity
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Colors.white70,
                  ), // Set the border color to white with some opacity
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Colors.white70,
                  ), // Set the border color to white with some opacity
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Colors.red,
                  ), // Set the border color to red
                ),
                suffixIcon: const Icon(
                  Icons.search,
                  color: Colors.white70,
                ), // Set the icon color to white with some opacity
              ),
              style: const TextStyle(
                color: Colors.white,
              ), // Set the text color to white
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredActivities.length,
              itemBuilder: (context, index) {
                final activity = _filteredActivities[index];
                return Card(
                  color:
                      Colors.grey.shade900, // Set the card color to dark grey
                  margin: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.directions_run,
                      color: Colors.red,
                      size: 28,
                    ),
                    title: Text(
                      activity['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white, // Set the text color to white
                      ),
                    ),
                    subtitle: Text(
                      "MET: ${activity['met']}",
                      style: const TextStyle(
                        fontSize: 14,
                        color:
                            Colors
                                .white70, // Set the text color to white with some opacity
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.add,
                        color: Colors.green,
                      ), // Set the icon color to green
                      onPressed: () => _onActivityTap(context, activity),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
