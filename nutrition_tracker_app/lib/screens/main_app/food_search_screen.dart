import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:barcode_scan2/barcode_scan2.dart';

import 'custom_meal_form_screen.dart';
import 'detailed_nutrition_screen.dart';

class FoodSearchScreen extends StatefulWidget {
  final String mealName;

  const FoodSearchScreen({super.key, required this.mealName});

  @override
  State<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends State<FoodSearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  late TabController _tabController;

  List<Map<String, dynamic>> _results = [];
  List<Map<String, dynamic>> _recentFoods = [];
  bool _isLoading = false;

  static const String _usdaApiKey =
      'USDA_KEY';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadRecentFoods();
  }

  Future<void> _loadRecentFoods() async {
    final prefs = await SharedPreferences.getInstance();
    final recentList = prefs.getStringList('recent_foods') ?? [];
    setState(() {
      _recentFoods =
          recentList
              .map((item) => json.decode(item))
              .cast<Map<String, dynamic>>()
              .toList();
    });
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _results = [];
    });

    List<Map<String, dynamic>> results = [];

    // Open Food Facts
    try {
      final response = await http.get(
        Uri.parse(
          'https://world.openfoodfacts.org/cgi/search.pl?search_terms=$query&search_simple=1&action=process&json=1&page_size=20',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        results.addAll(
          (data['products'] as List)
              .where((p) => p['product_name'] != null)
              .map((product) => _parseFoodData(product)),
        );
      }
    } catch (e) {
      print("Error fetching Open Food Facts data: $e");
    }

    // USDA
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.nal.usda.gov/fdc/v1/foods/search?api_key=$_usdaApiKey&query=$query&pageSize=15',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        results.addAll(
          (data['foods'] as List).map(
            (food) => _parseFoodData(food, isUSDA: true),
          ),
        );
      }
    } catch (e) {
      print("Error fetching USDA data: $e");
    }

    setState(() {
      _isLoading = false;
      _results = results;
    });
  }

  Future<void> _scanBarcode() async {
    try {
      // Start the barcode scanner
      final result = await BarcodeScanner.scan();

      if (result.rawContent.isEmpty) return; // User canceled the scan

      final barcode = result.rawContent;

      setState(() {
        _isLoading = true;
        _results = [];
      });

      List<Map<String, dynamic>> results = [];

      // Open Food Facts API
      try {
        final response = await http.get(
          Uri.parse(
            'https://world.openfoodfacts.org/api/v0/product/$barcode.json',
          ),
        );
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 1) {
            final product = data['product'];
            results.add(_parseFoodData(product));
          }
        }
      } catch (e) {
        print("Error fetching Open Food Facts data: $e");
      }

      // USDA API
      try {
        final response = await http.get(
          Uri.parse(
            'https://api.nal.usda.gov/fdc/v1/foods/search?api_key=$_usdaApiKey&query=$barcode&pageSize=1',
          ),
        );
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final foods = data['foods'] as List;
          if (foods.isNotEmpty) {
            final food = foods.first;
            results.add(_parseFoodData(food, isUSDA: true));
          }
        }
      } catch (e) {
        print("Error fetching USDA data: $e");
      }

      setState(() {
        _isLoading = false;
        _results = results;
      });

      if (results.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No food item found for this barcode.")),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to scan barcode.")));
    }
  }

  List<Map<String, dynamic>> _filteredResults() {
    if (_tabController.index == 0) {
      return _results
          .where((item) => item['brand'].isNotEmpty)
          .toList(); // Products
    } else if (_tabController.index == 1) {
      return _results.where((item) => item['brand'].isEmpty).toList(); // Meals
    } else {
      return _recentFoods; // Recent
    }
  }

  void _openCustomMealDialog() {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor:
                Colors.grey.shade900,
            title: const Text(
              "Create a custom meal?",
              style: TextStyle(
                color: Colors.white,
              ), 
            ),
            content: const Text(
              "Do you want to create a custom meal manually?",
              style: TextStyle(
                color: Colors.white70,
              ), 
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  "No",
                  style: TextStyle(
                    color: Color.fromARGB(255, 153, 21, 12),
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) =>
                              CustomMealFormScreen(mealName: widget.mealName),
                    ),
                  );
                },
                child: const Text(
                  "Yes",
                  style: TextStyle(
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  void _openDetailScreen(Map<String, dynamic> item) async {
    print("Opening Detail Screen with Food Data: $item"); // Debug log
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) =>
                DetailedNutritionScreen(mealName: widget.mealName, food: item),
      ),
    ).then((_) async {
      // Save the item to recent foods
      final prefs = await SharedPreferences.getInstance();
      final recentList = prefs.getStringList('recent_foods') ?? [];

      // Add the new item to the list
      final newItem = json.encode(item);
      if (!recentList.contains(newItem)) {
        recentList.add(newItem);
      }

      // Save the updated list back to SharedPreferences
      await prefs.setStringList('recent_foods', recentList);

      // Reload recent foods
      _loadRecentFoods();
    });
  }

  @override
  Widget build(BuildContext context) {
    final resultsToShow = _filteredResults();

    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            Colors.grey.shade900, 
        title: Text("Add to ${widget.mealName}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: "Create custom meal",
            onPressed: _openCustomMealDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          onTap: (_) => setState(() {}),
          tabs: const [
            Tab(text: "Products"),
            Tab(text: "Meals"),
            Tab(text: "Recent"),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_tabController.index != 2)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onSubmitted: (_) => _search(), // Trigger search on Enter
                      textInputAction:
                          TextInputAction.search, 
                      decoration: InputDecoration(
                        hintText: "Search food...",
                        hintStyle: const TextStyle(
                          color: Colors.white70,
                        ), 
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.white70,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.white70,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.red,
                          ),
                        ),
                        prefixIcon: const Icon(
                          Icons.search_outlined,
                          color: Colors.white70,
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(
                            Icons.qr_code_scanner,
                            color: Colors.white,
                          ),
                          tooltip: "Scan barcode",
                          onPressed: _scanBarcode, 
                        ),
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                      ), 
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      FocusManager.instance.primaryFocus
                          ?.unfocus();
                      _search();
                    },
                    icon: const Icon(Icons.search_outlined),
                    style: IconButton.styleFrom(
                      foregroundColor:
                          Colors.white, 
                      backgroundColor: const Color.fromARGB(
                        255,
                        163,
                        24,
                        14,
                      ), 
                    ),
                  ),
                ],
              ),
            ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Expanded(
              child:
                  resultsToShow.isEmpty
                      ? const Center(
                        child: Text(
                          "No results",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ) 
                      : ListView.builder(
                        itemCount: resultsToShow.length,
                        itemBuilder: (context, index) {
                          final item = resultsToShow[index];
                          final imageUrl =
                              item['image'] ?? ''; // Get the image URL

                          return Card(
                            color:
                                Colors
                                    .grey
                                    .shade900, 
                            margin: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 16,
                            ),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading:
                                  imageUrl.isNotEmpty
                                      ? Image.network(
                                        imageUrl,
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                        errorBuilder: (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
                                          return const Icon(
                                            Icons.image_not_supported,
                                            size: 50,
                                            color:
                                                Colors
                                                    .white70,
                                          );
                                        },
                                      )
                                      : const Icon(
                                        Icons.image_not_supported,
                                        size: 50,
                                        color:
                                            Colors
                                                .white70, 
                                      ),
                              title: Text(
                                item['name'],
                                style: const TextStyle(color: Colors.white),
                              ), 
                              subtitle: Text(
                                "${item['brand']} — ${item['calories'].toInt()} kcal",
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.white70,
                                ), 
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.add_circle,
                                  color: Color.fromARGB(255, 177, 20, 9),
                                ),
                                onPressed: () => _openDetailScreen(item),
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

Map<String, dynamic> _parseFoodData(
  Map<String, dynamic> product, {
  bool isUSDA = false,
}) {
  if (isUSDA) {
    print("Parsing USDA Data: $product");
    final nutrients = product['foodNutrients'] as List? ?? [];
    print("USDA Nutrients: $nutrients"); 
    double findNutrient(String name) {
      final match = nutrients.firstWhere(
        (n) => n['nutrientName'] == name,
        orElse: () => {'value': 0.0},
      );
      return (match['value'] ?? 0.0).toDouble();
    }

    return {
      'name': product['description'] ?? 'Unnamed',
      'brand': product['brandOwner'] ?? '',
      'calories': findNutrient('Energy'),
      'carbs': findNutrient('Carbohydrate, by difference'),
      'fat': findNutrient('Total lipid (fat)'),
      'protein': findNutrient('Protein'),
      'fiber': findNutrient('Fiber, total dietary'), 
      'sugar': findNutrient('Sugars, total including NLEA'), 
      'saturatedFat': findNutrient(
        'Fatty acids, total saturated',
      ), 
      'image': product['foodImage'] ?? '',
      'source': 'USDA',
    };
  } else {
    print("Parsing Open Food Facts Data: $product"); 
    final nutriments = product['nutriments'] ?? {};
    print("Open Food Facts Nutriments: $nutriments"); 
    return {
      'name': product['product_name'] ?? 'Unknown',
      'brand': product['brands'] ?? '',
      'calories': (nutriments['energy-kcal_100g'] ?? 0.0).toDouble(),
      'carbs': (nutriments['carbohydrates_100g'] ?? 0.0).toDouble(),
      'fat': (nutriments['fat_100g'] ?? 0.0).toDouble(),
      'protein': (nutriments['proteins_100g'] ?? 0.0).toDouble(),
      'fiber': (nutriments['fiber_100g'] ?? 0.0).toDouble(), 
      'sugar': (nutriments['sugars_100g'] ?? 0.0).toDouble(), 
      'saturatedFat':
          (nutriments['saturated-fat_100g'] ?? 0.0).toDouble(), 
      'image': product['image_url'] ?? '',
      'source': 'Open Food Facts',
    };
  }
}
