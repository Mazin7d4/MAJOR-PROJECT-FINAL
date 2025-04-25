import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nutrition_tracker_app/screens/main_app/popup/nutrient_chat_dialog.dart';

class DetailedNutritionScreen extends StatefulWidget {
  final Map<String, dynamic> food;
  final String mealName;

  const DetailedNutritionScreen({
    super.key,
    required this.food,
    required this.mealName,
  });

  @override
  State<DetailedNutritionScreen> createState() =>
      _DetailedNutritionScreenState();
}

class _DetailedNutritionScreenState extends State<DetailedNutritionScreen> {
  double _quantity = 1.0;
  String _mode = "Per Serving"; // or "Per Net Weight"

  double get netWeight => widget.food['quantity']?.toDouble() ?? 100.0;

  double get baseCalories => widget.food['calories'] ?? 0.0;
  double get baseCarbs => widget.food['carbs'] ?? 0.0;
  double get baseFat => widget.food['fat'] ?? 0.0;
  double get baseProtein => widget.food['protein'] ?? 0.0;

  Map<String, dynamic> get nutriments => widget.food['nutriments'] ?? {};

  double scaleFactor() {
    return _mode == "Per Serving" ? _quantity : _quantity * (netWeight / 100.0);
  }

  double get totalCalories => baseCalories * scaleFactor();
  double get totalCarbs => baseCarbs * scaleFactor();
  double get totalFat => baseFat * scaleFactor();
  double get totalProtein => baseProtein * scaleFactor();

  double get servingFactor => 30.0 / 100.0; // Scale factor for 30g serving

  double get servingCalories => baseCalories * servingFactor;
  double get servingCarbs => baseCarbs * servingFactor;
  double get servingFat => baseFat * servingFactor;
  double get servingProtein => baseProtein * servingFactor;
  double get servingSugar {
    // Access sugar directly from food map if available, otherwise fallback to nutriments
    return (widget.food['sugar'] ?? nutriments['sugars_100g'] ?? 0.0) *
        servingFactor;
  }

  double get servingFiber {
    // Access fiber directly from food map if available, otherwise fallback to nutriments
    return (widget.food['fiber'] ?? nutriments['fiber_100g'] ?? 0.0) *
        servingFactor;
  }

  double get servingSaturatedFat {
    // Access saturated fat directly from food map if available, otherwise fallback to nutriments
    return (widget.food['saturatedFat'] ??
            nutriments['saturated-fat_100g'] ??
            0.0) *
        servingFactor;
  }

  Future<Map<String, dynamic>> _fetchUserProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'weightKG': prefs.getDouble('weight') ?? 70,
      'heightCM': prefs.getDouble('height') ?? 175,
      'gender': prefs.getString('gender') ?? 'male',
      'goal': ["Lose", "Maintain", "Gain"][prefs.getInt('goal') ?? 1],
      'pal':
          [
            "Sedentary",
            "Light",
            "Moderate",
            "Active",
            "Very Active",
          ][prefs.getInt('activityLevel') ?? 1],
      'birthday': prefs.getString('dob'),
    };
  }

  void _openNutrientChatDialog() async {
    final userProfileData = await _fetchUserProfileData();

    // Use nutrients scaled to 30g per serving
    final nutritionTableData = {
      'energy': servingCalories, // Per 30g
      'carbohydrates': servingCarbs, // Per 30g
      'fat': servingFat, // Per 30g
      'protein': servingProtein, // Per 30g
      'fiber': servingFiber, // Per 30g
      'sugars': servingSugar, // Per 30g
      'saturated_fat': servingSaturatedFat, // Per 30g
      'salt': (nutriments['salt_100g'] ?? 0.0) * servingFactor, // Per 30g
    };

    final meal = MealEntity(
      name: widget.food['name'] ?? 'Food',
      brand: widget.food['brand'] ?? 'Unknown',
      quantity: _quantity,
      unit: _mode,
      servingQuantity: 30.0, // Fixed to 30g serving
      servingUnit: "g",
    );

    showDialog(
      context: context,
      builder:
          (_) => NutrientChatDialog(
            meal: meal,
            nutritionTableData: nutritionTableData,
            projectFoodFactsLink:
                "https://world.openfoodfacts.org", // Example link
            userProfileData: userProfileData,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final food = widget.food;
    final imageUrl = food['image'] ?? ''; // Get the image URL

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor:
            Colors.grey.shade900, // Set the background color to grey
        title: Text(food['name'] ?? 'Food Detail'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display the food image or fallback icon
            imageUrl.isNotEmpty
                ? Image.network(
                  imageUrl,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.image_not_supported,
                      size: 60,
                      color: Colors.grey,
                    );
                  },
                )
                : const Icon(
                  Icons.image_not_supported,
                  size: 60,
                  color: Colors.grey,
                ),
            const SizedBox(height: 20),
            Text(
              food['name'],
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ), // Set the text color to white
            ),
            if (food['brand'] != null)
              Text(
                food['brand'],
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ), // Set the text color to white with some opacity
              ),
            const SizedBox(height: 16),
            Text(
              "Calories : ${servingCalories.toStringAsFixed(0)} kcal per 30g serving",
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
              ), // Set the text color to white
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _macroTile("Carbs", "${servingCarbs.toStringAsFixed(1)}g"),
                _macroTile("Protein", "${servingProtein.toStringAsFixed(1)}g"),
                _macroTile("Fat", "${servingFat.toStringAsFixed(1)}g"),
              ],
            ),
            const SizedBox(height: 30),

            const SizedBox(height: 12),
            const Text(
              "Nutrition Table",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ), // Set the text color to white
            ),
            const SizedBox(height: 12),
            // Modernized table using Table widget
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2), // Nutrient column
                1: FlexColumnWidth(1), // Per 30g column
                2: FlexColumnWidth(1), // Per 100g column
              },
              border: TableBorder.symmetric(
                inside: BorderSide(color: Colors.grey, width: 0.5),
              ),
              children: [
                // Header row
                TableRow(
                  decoration: const BoxDecoration(color: Colors.grey),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "Nutrient",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "Per 30g",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "Per 100g",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                // Data rows
                _buildTableRow(
                  "Energy",
                  "${servingCalories.toStringAsFixed(0)} kcal",
                  "${baseCalories.toStringAsFixed(0)} kcal",
                ),
                _buildTableRow(
                  "Fat",
                  "${servingFat.toStringAsFixed(1)} g",
                  "${baseFat.toStringAsFixed(1)} g",
                ),
                _buildTableRow(
                  "Saturated Fat",
                  "${servingSaturatedFat.toStringAsFixed(1)} g",
                  "${(widget.food['saturatedFat'] ?? nutriments['saturated-fat_100g'] ?? 0.0).toStringAsFixed(1)} g",
                ),
                _buildTableRow(
                  "Carbohydrates",
                  "${servingCarbs.toStringAsFixed(1)} g",
                  "${baseCarbs.toStringAsFixed(1)} g",
                ),
                _buildTableRow(
                  "Sugars",
                  "${servingSugar.toStringAsFixed(1)} g",
                  "${(widget.food['sugar'] ?? nutriments['sugars_100g'] ?? 0.0).toStringAsFixed(1)} g",
                ),
                _buildTableRow(
                  "Fiber",
                  "${servingFiber.toStringAsFixed(1)} g",
                  "${(widget.food['fiber'] ?? nutriments['fiber_100g'] ?? 0.0).toStringAsFixed(1)} g",
                ),
                _buildTableRow(
                  "Protein",
                  "${servingProtein.toStringAsFixed(1)} g",
                  "${baseProtein.toStringAsFixed(1)} g",
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              "Quantity",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ), // Set the text color to white
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      hintText: "e.g. 1, 1.5, 2",
                      hintStyle: TextStyle(
                        color: Colors.white70,
                      ), // Set the hint text color to white with some opacity
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.white70,
                        ), // Set the border color to white with some opacity
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.white70,
                        ), // Set the border color to white with some opacity
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.red,
                        ), // Set the border color to red
                      ),
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                    ), // Set the text color to white
                    onChanged: (val) {
                      setState(() {
                        _quantity = double.tryParse(val) ?? 1.0;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: _mode,
                  dropdownColor:
                      Colors
                          .grey
                          .shade900, // Set the dropdown background color to dark grey
                  items: const [
                    DropdownMenuItem(
                      value: "Per Serving",
                      child: Text(
                        "Per Serving",
                        style: TextStyle(color: Colors.white),
                      ), // Set the text color to white
                    ),
                    DropdownMenuItem(
                      value: "Per Net Weight",
                      child: Text(
                        "Per Net Weight",
                        style: TextStyle(color: Colors.white),
                      ), // Set the text color to white
                    ),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _mode = val!;
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _openNutrientChatDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent, // Lighter red color
                minimumSize: const Size.fromHeight(50),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.chat,
                    size: 20,
                    color: Colors.white,
                  ), // AI Chat Icon
                  SizedBox(width: 8), // Space between icon and text
                  Text("AI Advise", style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _saveFood,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // Darker red color
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text("Add", style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _macroTile(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ), // Set the text color to white
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ), // Set the text color to white with some opacity
        ),
      ],
    );
  }

  Future<void> _saveFood() async {
    final prefs = await SharedPreferences.getInstance();
    final meal = widget.mealName.toLowerCase();

    // Use 30g per serving values
    final kcal = servingCalories; // Calories per 30g
    final carbs = servingCarbs; // Carbs per 30g
    final fat = servingFat; // Fat per 30g
    final protein = servingProtein; // Protein per 30g

    // Update daily macros
    await prefs.setInt(
      "${meal}_cals",
      (prefs.getInt("${meal}_cals") ?? 0) + (kcal * _quantity).toInt(),
    );
    await prefs.setDouble(
      'consumed',
      (prefs.getDouble('consumed') ?? 0) + (kcal * _quantity),
    );
    await prefs.setDouble(
      "${meal}_carbs",
      (prefs.getDouble("${meal}_carbs") ?? 0) + (carbs * _quantity),
    );
    await prefs.setDouble(
      "${meal}_fat",
      (prefs.getDouble("${meal}_fat") ?? 0) + (fat * _quantity),
    );
    await prefs.setDouble(
      "${meal}_protein",
      (prefs.getDouble("${meal}_protein") ?? 0) + (protein * _quantity),
    );

    // Save the entry itself
    final entry = {
      'name': widget.food['name'] ?? 'Food',
      'calories': (kcal * _quantity).toInt(), // Multiply calories by quantity
      'carbs': carbs * _quantity, // Multiply carbs by quantity
      'fat': fat * _quantity, // Multiply fat by quantity
      'protein': protein * _quantity, // Multiply protein by quantity
      'quantity': _quantity, // quantity
      'unit': "g", // Unit is grams
    };

    final key = "${meal}_entries";
    final List<String> current = prefs.getStringList(key) ?? [];
    current.add(json.encode(entry));
    await prefs.setStringList(key, current);

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  TableRow _buildTableRow(String label, String value1, String value2) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(label, style: const TextStyle(color: Colors.white)),
        ), // Set the text color to white
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            value1,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ), // Set the text color to white
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            value2,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ), // Set the text color to white
        ),
      ],
    );
  }
}
